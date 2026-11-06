import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage(StorageKey.learningLevel) private var storedLevel = LearningLevel.fallback.rawValue
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ObservedObject private var narrator = NorwegianVoice.shared
    @State private var showingSettings = false
    /// The level chooser opens by itself the first time, before anything is stored.
    @State private var showingChooser = UserDefaults.standard.object(forKey: StorageKey.learningLevel) == nil
    @AppStorage(StorageKey.islandStars) private var storedStars = ""

    private var level: LearningLevel {
        LearningLevel.resolve(storedLevel)
    }

    private var mapProgress: MapProgress {
        MapProgress(serialized: storedStars)
    }

    /// The narrated menu: the four games, then the map.
    private var menuItems: [(id: String, phrase: String)] {
        GameKind.allCases.map { (id: $0.accessibilityIdentifier, phrase: $0.title) }
            + [(id: "home.map", phrase: GameCopy.mapTitle)]
    }

    /// Cloud veil behind child-facing text that would otherwise sit on the scenery.
    private var veil: Color {
        GardenStyle.cloudVeil(opaque: reduceTransparency)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GardenBackground(style: .home)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        hero
                        journey
                        activities
                        progress
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 23)
                    .frame(maxWidth: 1030)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationDestination(for: GameKind.self) { game in
                switch game {
                case .build: BuildGameView()
                case .pair: PairGameView()
                case .split: SplitGameView()
                case .workshop: WorkshopView()
                }
            }
            .navigationDestination(for: MapRoute.self) { _ in
                IslandMapView()
            }
            .navigationDestination(for: MapNode.self) { node in
                ChallengePlayView(node: node)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $showingChooser) {
                LevelChooserView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if !showingChooser { narrateMenu() }
            }
            .onChange(of: showingChooser) {
                if !showingChooser { narrateMenu() }
            }
            .onChange(of: showingSettings) {
                if showingSettings { NorwegianVoice.shared.stop() }
            }
        }
        // The sound control stays at the bottom of every screen in the stack, on the grass.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GardenFooter {
                SoundToggleButton()
            }
        }
        .tint(GardenStyle.teal)
    }

    /// Reads "Velg en lek.", the four game names and the map; each card glows while it is named.
    private func narrateMenu() {
        NorwegianVoice.shared.narrate(intro: GameCopy.homeMenuIntro, items: menuItems, enabled: voice)
    }

    /// The card that opens Talløyene: the map of islands with its stars.
    private var journey: some View {
        NavigationLink(value: MapRoute.map) {
            MapCard(
                totalStars: mapProgress.totalStars(in: IslandMap.standard),
                maximumStars: MapProgress.maximumStars(in: IslandMap.standard),
                nextNode: mapProgress.nextNode(in: IslandMap.standard)
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .narrationGlow(narrator.narratedItem == "home.map", tint: GardenStyle.blue)
        .accessibilityLabel("\(GameCopy.mapTitle). Reis fra øy til øy og samle stjerner. \(GameCopy.stars(mapProgress.totalStars(in: IslandMap.standard))).")
        .accessibilityHint("Åpner kartet")
        .accessibilityIdentifier("home.map")
    }

    private var header: some View {
        HStack {
            // A wooden signboard at the garden gate (white on soil 5.56:1).
            Label("TALLHAGEN", systemImage: "leaf.fill")
                .font(.display(19))
                .tracking(2)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(GardenStyle.soil, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(GardenStyle.soilDeep, lineWidth: 2)
                }
                .accessibilityLabel("Tallhagen")
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Label("Innstillinger", systemImage: "gearshape.fill")
                    .font(.garden(.body, weight: .bold))
                    .padding(.horizontal, 17)
                    .frame(minHeight: 48)
                    .background(.white, in: Capsule())
                    .foregroundStyle(GardenStyle.ink)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityHint("Velg nivå og lyd")
            .accessibilityIdentifier("home.settings")
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 13) {
                Text("Tall er noe\nvi kan leke med!")
                    .font(.display(46))
                    .foregroundStyle(GardenStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Bygg, del og oppdag hvordan tall passer sammen.")
                    .font(.garden(.title3))
                    .foregroundStyle(GardenStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label(level.title, systemImage: "sparkles")
                        .font(.garden(.callout, weight: .bold))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .foregroundStyle(GardenStyle.teal)
                        .background(.white, in: Capsule())
                        .accessibilityLabel("Valgt nivå: \(level.title)")
                        .accessibilityIdentifier("home.level")

                    SecondaryActionButton(
                        label: "Velg tall",
                        symbol: "square.grid.2x2.fill",
                        tint: GardenStyle.teal,
                        identifier: "home.chooseLevel"
                    ) {
                        NorwegianVoice.shared.stop()
                        showingChooser = true
                    }
                }
            }
            .padding(24)
            .background(veil, in: RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
            }

            Spacer(minLength: 0)

            // Decorative example; dropped at compact widths (Split View, Slide Over).
            if horizontalSizeClass == .regular {
                VStack(spacing: 12) {
                    HStack(spacing: 13) {
                        BeadGroup(count: 3, tint: GardenStyle.teal, diameter: 22)
                        Text("+").font(.display(26, weight: .bold))
                        BeadGroup(count: 4, tint: GardenStyle.orange, diameter: 22)
                    }
                    HStack(spacing: 11) {
                        Text("3 + 4 =")
                            .font(.display(27))
                        Text("7")
                            .font(.display(46))
                            .foregroundStyle(GardenStyle.purple)
                    }
                    .foregroundStyle(GardenStyle.ink)
                }
                .padding(28)
                .background(.white, in: RoundedRectangle(cornerRadius: 30))
                .rotationEffect(.degrees(3))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Tre pluss fire er sju")
            }
        }
        .padding(.vertical, 8)
    }

    private var activities: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text("Velg en lek")
                    .font(.garden(.title, weight: .heavy))
                    .foregroundStyle(GardenStyle.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(veil, in: Capsule())
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                SecondaryActionButton(
                    label: "Les opp valgene",
                    symbol: "speaker.wave.2.fill",
                    tint: GardenStyle.teal,
                    identifier: "home.readMenu",
                    isSpeaking: narrator.narratedItem != nil
                ) {
                    NorwegianVoice.shared.narrate(intro: GameCopy.homeMenuIntro, items: menuItems, enabled: true)
                }
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 340, maximum: 500), spacing: 18)],
                spacing: 18
            ) {
                ForEach(GameKind.allCases) { game in
                    let isNarrated = narrator.narratedItem == game.accessibilityIdentifier
                    // Plain value for the Sendable transition closure below.
                    let keepsScale = reduceMotion
                    NavigationLink(value: game) {
                        GameCard(game: game, isNarrated: isNarrated)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .narrationGlow(isNarrated, tint: game.tint)
                    .accessibilityLabel("\(game.title). \(game.subtitle)")
                    .accessibilityHint("Åpner leken")
                    .accessibilityIdentifier(game.accessibilityIdentifier)
                    // Cards settle in as they scroll into view (opacity only under Reduce Motion).
                    .scrollTransition(.interactive) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.75)
                            .scaleEffect(keepsScale || phase.isIdentity ? 1 : 0.97)
                    }
                }
            }
        }
    }

    /// The progress card is also the garden bed: one flower per solved task, planted in
    /// groups of five with a larger gap after every ten. The sentence stays the only
    /// statement of progress; the bed is decoration.
    private var progress: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                progressStar

                VStack(alignment: .leading, spacing: 3) {
                    Text(GameCopy.tasksSolved(solvedTotal))
                        .font(.garden(.title3, weight: .bold))
                        .foregroundStyle(GardenStyle.ink)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("home.solvedTotal")
                    Text("Ingen tidsgrenser. Prøv så mange ganger du vil.")
                        .font(.garden(.subheadline))
                        .foregroundStyle(GardenStyle.muted)
                }
                Spacer()
            }
            .padding(21)

            GardenMeadow(bloomCount: solvedTotal)
                .frame(height: 76)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private var progressStar: some View {
        let star = Image(systemName: "star.circle.fill")
            .font(.system(size: 30))
            .foregroundStyle(GardenStyle.orange)
            .accessibilityHidden(true)
        if reduceMotion {
            star
        } else {
            star.symbolEffect(.bounce, value: solvedTotal)
        }
    }
}

private struct GameCard: View {
    let game: GameKind
    /// True while the narrator names this game: the guide perks up under the icon.
    var isNarrated: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(spacing: 8) {
                GameIcon(game: game, size: 78)
                CreatureView(creature: .forGame(game), mood: isNarrated ? .thinking : .idle, size: 64)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(game.title)
                    .font(.garden(.title2, weight: .heavy))
                    .foregroundStyle(GardenStyle.ink)

                Text(game.subtitle)
                    .font(.garden(.body))
                    .foregroundStyle(GardenStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text("Start")
                        .font(.garden(.subheadline, weight: .bold))
                        .foregroundStyle(GardenStyle.ink)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(game.tint)
                }
                .padding(.top, 6)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(GardenStyle.lightLine, lineWidth: 1.1)
        }
        // A thin grass line in the game's colour for the guide to stand on.
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(game.tint.opacity(0.18))
                .frame(height: 6)
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
                .accessibilityHidden(true)
        }
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.learningLevel) private var storedLevel = LearningLevel.fallback.rawValue
    @AppStorage(StorageKey.speakNorwegian) private var speakNorwegian = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @AppStorage(StorageKey.islandStars) private var storedStars = ""
    @State private var confirmingReset = false
    @State private var confirmingMapReset = false

    private var level: LearningLevel {
        LearningLevel.resolve(storedLevel)
    }

    private var mapStars: Int {
        MapProgress(serialized: storedStars).totalStars(in: IslandMap.standard)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Bound to the resolved level, so an unknown stored value still shows
                    // the level the app actually uses, and choosing a segment normalises it.
                    Picker(
                        "Nivå",
                        selection: Binding(
                            get: { LearningLevel.resolve(storedLevel) },
                            set: { storedLevel = $0.rawValue }
                        )
                    ) {
                        ForEach(LearningLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.level")

                    Text("Valgt: \(level.title). \(level.detail). Oppgavene i lekene går opp til \(level.maximum).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.levelDetail")
                } header: {
                    Text("Hvor store tall?")
                } footer: {
                    Text("Nivået kan endres når som helst. Antall løste oppgaver beholdes.")
                }

                Section {
                    Text("\(GameCopy.stars(mapStars)) av \(MapProgress.maximumStars(in: IslandMap.standard)) mulige")
                        .font(.subheadline)
                        .accessibilityIdentifier("settings.mapStars")
                    Button(role: .destructive) {
                        confirmingMapReset = true
                    } label: {
                        Label("Nullstill stjerner og låser på Talløyene", systemImage: "map")
                    }
                    .disabled(mapStars == 0)
                    .accessibilityIdentifier("settings.resetMap")
                } header: {
                    Text(GameCopy.mapTitle)
                } footer: {
                    Text("Stjernene åpner neste oppgave på kartet. Nullstilling låser alt unntatt den første oppgaven igjen; antall løste oppgaver beholdes.")
                }

                Section {
                    Toggle("Les opp på norsk", isOn: $speakNorwegian)
                        .accessibilityIdentifier("settings.speech")
                    Text("Appen leser opp menyer, oppgaver og svar med iPadens norske tale. Lydknappen nederst på skjermen slår det samme av og på.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Lyd")
                }

                Section {
                    Text(GameCopy.tasksSolved(solvedTotal))
                        .font(.subheadline)
                        .accessibilityIdentifier("settings.solvedTotal")
                    Button(role: .destructive) {
                        confirmingReset = true
                    } label: {
                        Label("Nullstill antall løste oppgaver", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(solvedTotal == 0)
                    .accessibilityIdentifier("settings.reset")
                } header: {
                    Text("Fremgang")
                } footer: {
                    Text("Tellingen lagres på denne iPaden.")
                }

                if !PrivacyPolicy.address.isEmpty {
                    // Plain text, neither a link nor selectable, so a child cannot leave the app from here:
                    // selectable text would offer Share on a long press, and Settings has no parental gate.
                    Section {
                        // The address gets a line of its own, so it never breaks after "https://".
                        // Text(verbatim:) keeps it plain: in a string literal SwiftUI would make it a link.
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appen samler ikke inn opplysninger. Personvernerklæring:")
                            Text(verbatim: PrivacyPolicy.address)
                        }
                        .font(.subheadline)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("settings.privacy")
                    } header: {
                        Text("Personvern")
                    }
                }

                Section {
                    Text("Ingen reklame, abonnement, konto eller nettforbindelse. Fremgang lagres på denne iPaden.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Om Tallhagen")
                }
            }
            .navigationTitle("Innstillinger")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig") { dismiss() }
                        .accessibilityIdentifier("settings.done")
                }
            }
            .confirmationDialog(
                "Vil du sette antall løste oppgaver til 0?",
                isPresented: $confirmingReset,
                titleVisibility: .visible
            ) {
                Button("Nullstill", role: .destructive) {
                    solvedTotal = 0
                }
                Button("Avbryt", role: .cancel) {}
            }
            .confirmationDialog(
                "Vil du låse alle oppgavene på Talløyene igjen og fjerne stjernene?",
                isPresented: $confirmingMapReset,
                titleVisibility: .visible
            ) {
                Button("Nullstill Talløyene", role: .destructive) {
                    storedStars = ""
                }
                Button("Avbryt", role: .cancel) {}
            }
        }
    }
}

/// Original, text-free icons for the four activities, drawn with plain shapes so they stay
/// crisp at any size and need no artwork files. Each one shows the game's own idea with dots:
/// a tower of pieces, a dot looking for its missing friend, a group split in two, and a
/// plus/minus workshop.
struct GameIcon: View {
    let game: GameKind
    var size: CGFloat = 66

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29)
                .fill(game.tint.opacity(0.12))
            drawing
                .frame(width: size * 0.64, height: size * 0.64)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var drawing: some View {
        switch game {
        case .build: buildIcon
        case .pair: pairIcon
        case .split: splitIcon
        case .workshop: workshopIcon
        }
    }

    private var dot: CGFloat { size * 0.085 }

    /// Three stacked pieces, each holding its dots.
    private var buildIcon: some View {
        VStack(spacing: size * 0.04) {
            piece(dots: 1, width: size * 0.26)
            piece(dots: 2, width: size * 0.42)
            piece(dots: 3, width: size * 0.58)
        }
    }

    private func piece(dots: Int, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.06)
            .fill(game.tint)
            .frame(width: width, height: size * 0.16)
            .overlay {
                HStack(spacing: size * 0.04) {
                    ForEach(0..<dots, id: \.self) { _ in
                        Circle().fill(.white).frame(width: dot, height: dot)
                    }
                }
            }
    }

    /// A dot and the dashed outline of the friend it is looking for, joined by a plus.
    private var pairIcon: some View {
        HStack(spacing: size * 0.05) {
            Circle()
                .fill(game.tint)
                .frame(width: size * 0.24, height: size * 0.24)
            Image(systemName: "plus")
                .font(.system(size: size * 0.16, weight: .heavy))
                .foregroundStyle(game.tint)
            Circle()
                .strokeBorder(game.tint, style: StrokeStyle(lineWidth: size * 0.035, dash: [size * 0.06, size * 0.045]))
                .frame(width: size * 0.24, height: size * 0.24)
        }
    }

    /// Six dots with a dashed cut between the two groups.
    private var splitIcon: some View {
        HStack(spacing: size * 0.07) {
            dotColumn(count: 2)
            dotColumn(count: 2)
            Rectangle()
                .fill(.clear)
                .frame(width: size * 0.035, height: size * 0.5)
                .overlay {
                    Path { path in
                        path.move(to: CGPoint(x: size * 0.0175, y: 0))
                        path.addLine(to: CGPoint(x: size * 0.0175, y: size * 0.5))
                    }
                    .stroke(game.tint, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round, dash: [size * 0.06, size * 0.06]))
                }
            dotColumn(count: 2)
        }
    }

    private func dotColumn(count: Int) -> some View {
        VStack(spacing: size * 0.06) {
            ForEach(0..<count, id: \.self) { _ in
                Circle().fill(game.tint).frame(width: size * 0.15, height: size * 0.15)
            }
        }
    }

    /// Plus and minus keys under a row of dots: the workshop's two controls.
    private var workshopIcon: some View {
        VStack(spacing: size * 0.08) {
            HStack(spacing: size * 0.05) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(game.tint).frame(width: size * 0.13, height: size * 0.13)
                }
            }
            HStack(spacing: size * 0.06) {
                key("minus")
                key("plus")
            }
        }
    }

    private func key(_ symbol: String) -> some View {
        RoundedRectangle(cornerRadius: size * 0.07)
            .fill(game.tint)
            .frame(width: size * 0.26, height: size * 0.2)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.13, weight: .heavy))
                    .foregroundStyle(.white)
            }
    }
}

/// First-launch choice of number range, built for children who cannot read much yet:
/// three big cards showing the number and its dots, read aloud one by one with a glow.
/// Reachable again from the home screen's "Velg tall" button.
struct LevelChooserView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.learningLevel) private var storedLevel = LearningLevel.fallback.rawValue
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ObservedObject private var narrator = NorwegianVoice.shared

    private static let tints: [LearningLevel: Color] = [
        .practice: GardenStyle.teal, .advanced: GardenStyle.purple, .hundred: GardenStyle.orange,
    ]

    var body: some View {
        ZStack {
            GardenBackground(style: .chooser)

            ScrollView {
                VStack(spacing: 26) {
                    // Title and instruction on one cloud veil, with the butterfly looking on.
                    VStack(spacing: 10) {
                        Text("Hvor store tall?")
                            .font(.display(44))
                            .foregroundStyle(GardenStyle.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("start.title")

                        Text("Trykk på det du vil leke med.")
                            .font(.garden(.title3))
                            .foregroundStyle(GardenStyle.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: 620)
                    .background(GardenStyle.cloudVeil(opaque: reduceTransparency), in: RoundedRectangle(cornerRadius: 30))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30)
                            .strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
                    }
                    .overlay(alignment: .trailing) {
                        if horizontalSizeClass == .regular {
                            CreatureView(creature: .butterfly, mood: .idle, size: 56)
                                .offset(x: 12, y: -16)
                        }
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 22) {
                            choices(withPosts: true)
                        }
                        VStack(spacing: 18) {
                            choices(withPosts: false)
                        }
                    }

                    SecondaryActionButton(
                        label: "Les opp valgene",
                        symbol: "speaker.wave.2.fill",
                        tint: GardenStyle.teal,
                        identifier: "start.readChoices",
                        isSpeaking: narrator.narratedItem != nil
                    ) {
                        narrate(enabled: true)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 30)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GardenFooter {
                SoundToggleButton()
            }
        }
        .onAppear { narrate(enabled: voice) }
        .onDisappear { NorwegianVoice.shared.stop() }
    }

    /// The three cards; in the side-by-side row each one stands on a small wooden post.
    @ViewBuilder
    private func choices(withPosts: Bool) -> some View {
        ForEach(LearningLevel.starterChoices) { level in
            let tint = Self.tints[level] ?? GardenStyle.teal
            Button {
                choose(level)
            } label: {
                LevelChoiceCard(level: level, tint: tint)
            }
            .buttonStyle(BouncyButtonStyle())
            .narrationGlow(narrator.narratedItem == Self.identifier(for: level), tint: tint, cornerRadius: 30)
            .padding(.bottom, withPosts ? 22 : 0)
            .background(alignment: .bottom) {
                if withPosts {
                    Capsule()
                        .fill(GardenStyle.soilLight)
                        .overlay {
                            Capsule().strokeBorder(GardenStyle.soilDeep.opacity(0.6), lineWidth: 1.5)
                        }
                        .frame(width: 12, height: 28)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("\(level.title). Tall fra 1 til \(level.maximum).")
            .accessibilityHint("Velger dette tallområdet")
            .accessibilityIdentifier(Self.identifier(for: level))
        }
    }

    static func identifier(for level: LearningLevel) -> String {
        "start.level.\(level.rawValue)"
    }

    private func choose(_ level: LearningLevel) {
        storedLevel = level.rawValue
        TouchFeedback.success()
        dismiss()
    }

    private func narrate(enabled: Bool) {
        NorwegianVoice.shared.narrate(
            intro: GameCopy.levelChooserIntro,
            items: LearningLevel.starterChoices.map { (id: Self.identifier(for: $0), phrase: GameCopy.levelChoice($0)) },
            enabled: enabled
        )
    }
}

/// One range to pick: the biggest number, its dots at a glance, and the short label.
private struct LevelChoiceCard: View {
    let level: LearningLevel
    let tint: Color

    var body: some View {
        VStack(spacing: 14) {
            Text("\(level.maximum)")
                .font(.display(64))
                .monospacedDigit()
                .foregroundStyle(tint)
            BeadGroup(
                count: level.maximum,
                tint: tint,
                diameter: level.dotColumns > 5 ? 9 : 11,
                maxColumns: level.dotColumns
            )
            Text(level.title)
                .font(.garden(.title3, weight: .bold))
                .foregroundStyle(GardenStyle.ink)
        }
        .frame(width: 236)
        .padding(.vertical, 24)
        .padding(.horizontal, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
        }
    }
}
