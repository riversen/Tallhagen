import SwiftUI

// Talløyene: running one map node as a challenge. The host counts solved tasks and mistakes
// while an ordinary activity view plays its puzzles at the node's fixed range; `GameScaffold`
// swaps its title row for the minimal status strip below, and the completion card stores the
// stars under `StorageKey.islandStars`. Everything here is SwiftUI glue: the rules live in
// MathLogic.swift (`ChallengeRules`, `MapProgress`, `IslandMap`) and the state machine in
// GameSessions.swift (`ChallengeRun`).

/// Shared by the challenge screen and the activity it hosts. Activity views report every
/// `AnswerOutcome` here; the screen and the status strip observe the run.
final class ChallengeHost: ObservableObject {
    let node: MapNode
    @Published private(set) var run: ChallengeRun

    init(node: MapNode) {
        self.node = node
        self.run = ChallengeRun(taskCount: node.taskCount)
    }

    func report(_ outcome: AnswerOutcome) {
        guard !run.isComplete else { return }
        run.record(outcome)
    }

    func restart() {
        run = ChallengeRun(taskCount: node.taskCount)
    }
}

private struct ChallengeHostKey: EnvironmentKey {
    static let defaultValue: ChallengeHost? = nil
}

extension EnvironmentValues {
    /// Set while an activity plays inside a map node; nil on the free-play screens.
    var challengeHost: ChallengeHost? {
        get { self[ChallengeHostKey.self] }
        set { self[ChallengeHostKey.self] = newValue }
    }
}

extension MapGuide {
    /// The drawn guide that hosts the island.
    var creature: GardenCreature {
        switch self {
        case .snail: return .snail
        case .butterfly: return .butterfly
        case .bee: return .bee
        case .hedgehog: return .hedgehog
        }
    }
}

extension MapActivity {
    /// The activity's colour on the map, in the status strip and on the completion card.
    var tint: Color {
        switch self {
        case .build: return GardenStyle.teal
        case .pair: return GardenStyle.orange
        case .split: return GardenStyle.purple
        case .barBuild, .barSplit: return GardenStyle.blue
        case .placeValue: return GardenStyle.soil
        case .balance: return GardenStyle.tealDeep
        }
    }

    /// The free-play game whose icon the node carries, if the activity is one of the four.
    var gameKind: GameKind? {
        switch self {
        case .build: return .build
        case .pair: return .pair
        case .split: return .split
        case .barBuild, .barSplit, .placeValue, .balance: return nil
        }
    }
}

/// One map node on screen: the activity at the node's range, the run counted by the host,
/// and the completion card with the stars once every task is solved.
struct ChallengePlayView: View {
    let node: MapNode
    @StateObject private var host: ChallengeHost
    @AppStorage(StorageKey.islandStars) private var storedStars = ""
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingCompletion = false
    /// Changes on "Spill igjen" so the activity view starts over.
    @State private var attempt = 0
    /// The short wait before the card; cancelled when the child leaves or plays again.
    @State private var completionTask: Task<Void, Never>?

    init(node: MapNode) {
        self.node = node
        _host = StateObject(wrappedValue: ChallengeHost(node: node))
    }

    var body: some View {
        ZStack {
            activity
                .id(attempt)
                .environment(\.challengeHost, host)
                // Once the last task is solved nothing below starts a fifth one while the
                // card is on its way.
                .allowsHitTesting(!host.run.isComplete)
                .accessibilityHidden(showingCompletion)
            if showingCompletion {
                ChallengeCompletionCard(
                    stars: host.run.stars,
                    guide: (IslandMap.standard.island(containing: node)?.guide ?? .snail).creature,
                    tint: node.activity.tint,
                    toMap: {
                        NorwegianVoice.shared.stop()
                        dismiss()
                    },
                    again: playAgain
                )
                .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onChange(of: host.run.isComplete) { _, complete in
            if complete { finish() }
        }
        .onDisappear {
            completionTask?.cancel()
            completionTask = nil
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var activity: some View {
        switch node.activity {
        case .build(let level): BuildGameView(level: level)
        case .pair(let level): PairGameView(level: level)
        case .split(let level): SplitGameView(level: level)
        case .barBuild, .barSplit: BarGameView(activity: node.activity)
        case .placeValue(let task, let level): PlaceValueView(task: task, level: level)
        case .balance(let phase): BalanceView(phase: phase)
        }
    }

    /// Stores the stars at once (the best result is kept), then shows the card after the child
    /// has seen the last puzzle's success. The completion sentence waits for the success
    /// sentence to finish. Nothing happens if the child has left the node in the meantime.
    private func finish() {
        var progress = MapProgress(serialized: storedStars)
        progress.record(stars: host.run.stars, for: node)
        storedStars = progress.serialized
        let delay = reduceMotion ? 0.2 : 1.1
        completionTask?.cancel()
        completionTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, host.run.isComplete, !showingCompletion else { return }
            withAnimation(Motion.spring(reduceMotion)) {
                showingCompletion = true
            }
            SoundCuePlayer.shared.play(.applause, enabled: voice)
            let sentence = GameCopy.challengeComplete + " " + GameCopy.challengeResult(stars: host.run.stars)
            VoiceOverAnnouncer.announce(sentence)
            NorwegianVoice.shared.sayAfterCurrent(sentence, enabled: voice)
        }
    }

    private func playAgain() {
        completionTask?.cancel()
        completionTask = nil
        NorwegianVoice.shared.stop()
        SoundCuePlayer.shared.play(.paper, enabled: voice)
        withAnimation(Motion.quick(reduceMotion)) {
            showingCompletion = false
        }
        host.restart()
        attempt += 1
    }
}

/// The minimal status strip of a challenge: back to the map, the node number, one leaf per
/// task (filled when solved), the activity name and the island's guide. Replaces the title
/// row of `GameScaffold` while a challenge runs. The sound button stays in the footer.
struct ChallengeStatusStrip: View {
    @ObservedObject var host: ChallengeHost
    let tint: Color
    let creature: GardenCreature?
    let mood: CreatureMood
    let progress: Double

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsExtras: Bool {
        horizontalSizeClass == .regular && dynamicTypeSize < .xxLarge
    }

    /// The island's guide, as on the map and on the completion card; the activity's own
    /// creature only for a node outside the standard map.
    private var guide: GardenCreature? {
        IslandMap.standard.island(containing: host.node)?.guide.creature ?? creature
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                NorwegianVoice.shared.stop()
                SoundCuePlayer.shared.play(.paper)
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(GardenStyle.ink)
                    .frame(width: 56, height: 48)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityLabel(GameCopy.challengeToMap)
            .accessibilityIdentifier("challenge.back")

            Text("\(host.node.number)")
                .font(.display(24))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(tint, in: Circle())
                .accessibilityLabel(GameCopy.mapNode(number: host.node.number, title: host.node.activity.title))
                .accessibilityIdentifier("challenge.node")

            HStack(spacing: 6) {
                ForEach(0..<host.run.taskCount, id: \.self) { index in
                    Image(systemName: index < host.run.solved ? "leaf.fill" : "leaf")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(index < host.run.solved ? tint : GardenStyle.muted.opacity(0.55))
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(.white, in: Capsule())
            .animation(Motion.quick(reduceMotion), value: host.run.solved)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(host.run.progressText)
            .accessibilityIdentifier("challenge.progress")

            if showsExtras {
                Text(host.node.activity.title)
                    .font(.garden(.subheadline, weight: .bold))
                    .foregroundStyle(GardenStyle.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .background(.white, in: Capsule())
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            if showsExtras, let guide {
                CreatureView(creature: guide, mood: mood, size: 64)
                    .environment(\.creatureProgress, progress)
            }
        }
    }
}

/// Shown over the activity when every task of a node is solved: the island's guide, the
/// earned stars (popping in one by one unless Reduce Motion is on), the spoken summary and
/// the way back to the map or into the node again.
struct ChallengeCompletionCard: View {
    let stars: Int
    let guide: GardenCreature
    let tint: Color
    let toMap: () -> Void
    let again: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownStars = 0

    var body: some View {
        ZStack {
            // Dims and blocks the solved puzzle underneath.
            GardenStyle.ink.opacity(0.28)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 18) {
                CreatureView(creature: guide, mood: .happy, size: 96)

                Text(GameCopy.challengeComplete)
                    .font(.display(32))
                    .foregroundStyle(GardenStyle.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("challenge.complete")

                HStack(spacing: 14) {
                    ForEach(0..<ChallengeRules.maximumStars, id: \.self) { index in
                        Image(systemName: index < stars ? "star.fill" : "star")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundStyle(index < stars ? GardenStyle.orange : GardenStyle.lightLine)
                            .scaleEffect(index < shownStars ? 1 : 0.3)
                            .opacity(index < shownStars ? 1 : 0)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(GameCopy.stars(stars))

                Text(GameCopy.challengeResult(stars: stars))
                    .font(.garden(.title3, weight: .semibold))
                    .foregroundStyle(GardenStyle.ink)
                    .accessibilityIdentifier("challenge.stars")

                BigActionButton(
                    label: GameCopy.challengeToMap,
                    symbol: "map.fill",
                    tint: tint,
                    identifier: "challenge.toMap",
                    hint: "Går tilbake til Talløyene",
                    sound: .paper,
                    action: toMap
                )

                SecondaryActionButton(
                    label: GameCopy.challengeAgain,
                    symbol: "arrow.counterclockwise",
                    tint: tint,
                    identifier: "challenge.again",
                    action: again
                )
            }
            .padding(30)
            .frame(maxWidth: 440)
            .background(.white, in: RoundedRectangle(cornerRadius: 32))
            .overlay {
                RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
            }
            .padding(24)
        }
        .onAppear(perform: revealStars)
    }

    private func revealStars() {
        if reduceMotion {
            shownStars = ChallengeRules.maximumStars
            return
        }
        for index in 0..<ChallengeRules.maximumStars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + 0.22 * Double(index)) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    shownStars = index + 1
                }
            }
        }
    }
}
