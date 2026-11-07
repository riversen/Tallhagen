import SwiftUI

// Talløyene: the map of garden islands in a pond. Islands run from left to right in a
// horizontal scroll (landscape first; portrait scrolls the same way), each hosted by one of the
// four guides and carrying its numbered stepping stones: a padlock while locked, the number
// once open, and the earned stars underneath once complete. Stepping-stone paths join the
// nodes and the islands. The map is textless apart from the island names on their signs and
// the title; every node is spoken through its accessibility label and the narration. Content
// and unlock rules live in MathLogic.swift (`IslandMap`, `MapProgress`).

/// Navigation value for the map itself (nodes navigate by `MapNode`).
enum MapRoute: Hashable {
    case map
}

struct IslandMapView: View {
    @AppStorage(StorageKey.islandStars) private var storedStars = ""
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var narrator = NorwegianVoice.shared

    private let map = IslandMap.standard

    private var progress: MapProgress { MapProgress(serialized: storedStars) }
    private var islandWidth: CGFloat { horizontalSizeClass == .compact ? 300 : 360 }

    /// Islands with more than four stones grow, so the stones keep the spacing of a four-stone
    /// island (about 70 pt, 58 in the compact width class) and never overlap.
    private func width(of island: Island) -> CGFloat {
        let pitch: CGFloat = horizontalSizeClass == .compact ? 58 : 70
        return max(islandWidth, CGFloat(max(island.nodes.count - 1, 1)) * pitch / IslandView.spanFraction)
    }

    var body: some View {
        ZStack {
            GardenBackground(style: .game(GardenStyle.blue))

            VStack(alignment: .leading, spacing: 0) {
                strip
                    .padding(.horizontal, 26)
                    .padding(.top, 23)
                    .padding(.bottom, 12)

                // The pond sits in the middle of whatever height is left (the safe central
                // area), so portrait and landscape both centre the island row.
                Spacer(minLength: 0)

                ScrollViewReader { scroller in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .center, spacing: 0) {
                            ForEach(map.islands) { island in
                                IslandView(
                                    island: island,
                                    map: map,
                                    progress: progress,
                                    isFirst: island.id == map.islands.first?.id,
                                    isLast: island.id == map.islands.last?.id,
                                    width: width(of: island),
                                    narratedNodeID: narratedNodeID
                                )
                                .id(island.id)
                            }
                        }
                        .padding(.horizontal, 26)
                        .padding(.vertical, 18)
                        .background {
                            PondBand()
                                .padding(.horizontal, 10)
                        }
                    }
                    .onAppear {
                        if let next = progress.nextNode(in: map), let island = map.island(containing: next) {
                            scroller.scrollTo(island.id, anchor: .center)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .footerClearance()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { narrate(enabled: voice) }
    }

    /// Back, title, the star total and the read-aloud button: one row on a full-screen iPad,
    /// two rows in a narrow window (Slide Over, a third of Split View), so the back button
    /// never leaves the screen.
    private var strip: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                backButton
                title
                Spacer(minLength: 0)
                starTotal
                readButton
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    backButton
                    title
                    Spacer(minLength: 0)
                }
                HStack(spacing: 14) {
                    starTotal
                    readButton
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var backButton: some View {
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
        .accessibilityLabel("Tilbake")
        .accessibilityHint("Går tilbake til startsiden")
        .accessibilityIdentifier("map.back")
    }

    private var title: some View {
        Text(GameCopy.mapTitle)
            .font(.display(34))
            .foregroundStyle(GardenStyle.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("map.title")
    }

    private var starTotal: some View {
        Label {
            Text("\(progress.totalStars(in: map)) av \(MapProgress.maximumStars(in: map))")
                .font(.garden(.body, weight: .bold))
                .foregroundStyle(GardenStyle.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
        } icon: {
            Image(systemName: "star.fill")
                .foregroundStyle(GardenStyle.orange)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(.white, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(GameCopy.stars(progress.totalStars(in: map))) av \(MapProgress.maximumStars(in: map)) mulige")
        .accessibilityIdentifier("map.stars")
    }

    private var readButton: some View {
        SecondaryActionButton(
            label: "Les opp",
            symbol: "speaker.wave.2.fill",
            tint: GardenStyle.blue,
            identifier: "map.readIntro",
            isSpeaking: narrator.narratedItem != nil
        ) {
            narrate(enabled: true)
        }
    }

    private var narratedNodeID: String? {
        guard let item = narrator.narratedItem, item.hasPrefix("map.node.") else { return nil }
        return String(item.dropFirst("map.node.".count))
    }

    /// "Velkommen til Talløyene…" and then the next open node, which glows while it is named.
    private func narrate(enabled: Bool) {
        var items: [(id: String, phrase: String)] = []
        if let next = progress.nextNode(in: map) {
            items.append((id: "map.node.\(next.id)", phrase: GameCopy.mapNode(number: next.number, title: next.activity.title)))
        }
        NorwegianVoice.shared.narrate(intro: GameCopy.mapIntro, items: items, enabled: enabled)
    }
}

/// The pond the islands stand in: pale water with a few thin ripples (capsules, never dots).
private struct PondBand: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 70, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [GardenStyle.skyTop, GardenStyle.skyPale],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Canvas { context, size in
                    var index = 0
                    var x: CGFloat = 40
                    while x < size.width - 40 {
                        let y = 24 + CGFloat((index * 37) % 5) * 12 + (index % 2 == 0 ? 0 : size.height - 90)
                        let ripple = Path(roundedRect: CGRect(x: x, y: y, width: 34, height: 4), cornerRadius: 2)
                        context.fill(ripple, with: .color(.white.opacity(0.55)))
                        x += 150 + CGFloat((index * 53) % 60)
                        index += 1
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 70, style: .continuous)
                    .strokeBorder(GardenStyle.sand.opacity(0.9), lineWidth: 6)
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// One island: sand rim, two layers of grass, the guide, the sign and the nodes on a gentle
/// wave, joined by dotted stepping-stone paths that continue to the neighbouring islands.
private struct IslandView: View {
    let island: Island
    let map: IslandMap
    let progress: MapProgress
    let isFirst: Bool
    let isLast: Bool
    let width: CGFloat
    let narratedNodeID: String?

    private let height: CGFloat = 340
    private static let wave: [CGFloat] = [16, -28, 14, -24]

    /// Share of the island's width that the stones span.
    static let spanFraction: CGFloat = 0.58

    private func nodeCentre(_ index: Int) -> CGPoint {
        let count = island.nodes.count
        let startX = width * 0.21
        let span = width * Self.spanFraction
        let x = count == 1 ? width / 2 : startX + span * CGFloat(index) / CGFloat(count - 1)
        return CGPoint(x: x, y: height * 0.58 + Self.wave[index % Self.wave.count])
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ground

            // Stepping stones: round dots along the way, including the bridges to the neighbours.
            Path { path in
                let centres = island.nodes.indices.map(nodeCentre)
                if !isFirst, let first = centres.first {
                    path.move(to: CGPoint(x: -10, y: first.y))
                    path.addLine(to: first)
                }
                for (from, to) in zip(centres, centres.dropFirst()) {
                    path.move(to: from)
                    path.addLine(to: to)
                }
                if !isLast, let last = centres.last {
                    path.move(to: last)
                    path.addLine(to: CGPoint(x: width + 10, y: last.y))
                }
            }
            .stroke(GardenStyle.sandDeep.opacity(0.75), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [0.1, 14]))
            .accessibilityHidden(true)

            CreatureView(creature: island.guide.creature, mood: .idle, size: 72)
                .position(x: width * 0.16, y: height * 0.26)

            IslandSign(island: island)
                .position(x: width * 0.56, y: height * 0.17)

            ForEach(Array(island.nodes.enumerated()), id: \.element.id) { index, node in
                MapNodeButton(
                    node: node,
                    stars: progress.stars(for: node),
                    isUnlocked: progress.isUnlocked(node, in: map),
                    isNext: progress.nextNode(in: map) == node,
                    isNarrated: narratedNodeID == node.id
                )
                .position(x: nodeCentre(index).x, y: nodeCentre(index).y + 12)
            }
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Øy \(island.number): \(island.title)")
    }

    private var ground: some View {
        ZStack {
            Ellipse()
                .fill(GardenStyle.sand)
                .overlay { Ellipse().strokeBorder(GardenStyle.sandDeep.opacity(0.5), lineWidth: 1.5) }
                .frame(width: width * 0.92, height: height * 0.74)
                .position(x: width / 2, y: height * 0.56)
            Ellipse()
                .fill(GardenStyle.hillMid)
                .frame(width: width * 0.84, height: height * 0.62)
                .position(x: width / 2, y: height * 0.54)
            Ellipse()
                .fill(GardenStyle.hillNear)
                .frame(width: width * 0.66, height: height * 0.4)
                .position(x: width * 0.52, y: height * 0.5)
            GardenFlower(tint: GardenStyle.petalPink, size: 30)
                .position(x: width * 0.09, y: height * 0.62)
            GardenFlower(tint: GardenStyle.lilac, size: 26)
                .position(x: width * 0.9, y: height * 0.36)
            GardenFlower(tint: GardenStyle.sunGlow, size: 28)
                .position(x: width * 0.86, y: height * 0.8)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// The island's wooden sign: its number in a disc and its name (white on soil, 5.56:1).
private struct IslandSign: View {
    let island: Island

    var body: some View {
        HStack(spacing: 10) {
            Text("\(island.number)")
                .font(.display(18))
                .foregroundStyle(GardenStyle.soilDeep)
                .frame(width: 30, height: 30)
                .background(GardenStyle.sand, in: Circle())
            Text(island.title)
                .font(.garden(.subheadline, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(GardenStyle.soil, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(GardenStyle.soilDeep, lineWidth: 2)
        }
        .accessibilityHidden(true)
    }
}

/// One stepping stone: a padlock while locked, the number once open (with the activity's glyph
/// at its shoulder), and the stars underneath once complete. The next node to play glows softly.
private struct MapNodeButton: View {
    let node: MapNode
    let stars: Int
    let isUnlocked: Bool
    let isNext: Bool
    let isNarrated: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color { node.activity.tint }

    var body: some View {
        NavigationLink(value: node) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.white : GardenStyle.lightLine)
                    Circle()
                        .strokeBorder(isUnlocked ? tint : GardenStyle.muted.opacity(0.45), lineWidth: 4)
                    if isUnlocked {
                        Text("\(node.number)")
                            .font(.display(30))
                            .monospacedDigit()
                            .foregroundStyle(GardenStyle.ink)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(GardenStyle.muted)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 68, height: 68)
                .background {
                    if isNext && !reduceMotion {
                        NextNodeHalo(tint: tint)
                    } else if isNext {
                        Circle().fill(tint.opacity(0.22)).frame(width: 92, height: 92)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isUnlocked {
                        ActivityGlyph(activity: node.activity, size: 30)
                            .offset(x: 10, y: -8)
                    }
                }
                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)

                StarRow(stars: stars, size: 15)
                    .opacity(stars > 0 ? 1 : 0)
            }
            .frame(width: 90)
            .animation(Motion.spring(reduceMotion), value: isUnlocked)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!isUnlocked)
        // An open stone answers with the paper slide, a locked one with the soft knock.
        .simultaneousGesture(TapGesture().onEnded { SoundCuePlayer.shared.play(isUnlocked ? .paper : .knock) })
        .narrationGlow(isNarrated, tint: tint, cornerRadius: 44)
        .accessibilityLabel(label)
        .accessibilityHint(isUnlocked ? "Åpner oppgaven" : "")
        .accessibilityIdentifier("map.node.\(node.id)")
    }

    private var label: String {
        var text = GameCopy.mapNode(number: node.number, title: node.activity.title)
        if !isUnlocked {
            text += " " + GameCopy.mapLocked(number: node.number)
        } else if stars > 0 {
            text += " " + GameCopy.stars(stars) + "."
        }
        return text
    }
}

/// A slow breathing halo behind the node to play next (1.6 s period, scale 1 to 1.1).
private struct NextNodeHalo: View {
    let tint: Color

    var body: some View {
        PhaseAnimator([1.0, 1.1]) { scale in
            Circle()
                .fill(tint.opacity(0.22))
                .frame(width: 92, height: 92)
                .scaleEffect(scale)
        } animation: { _ in
            .easeInOut(duration: 0.8)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Three stars: filled orange for earned ones, light outlines for the rest.
struct StarRow: View {
    let stars: Int
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<ChallengeRules.maximumStars, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(index < stars ? GardenStyle.orange : GardenStyle.muted.opacity(0.45))
            }
        }
        .accessibilityHidden(true)
    }
}

/// The small picture that says which activity a node holds: the game's own icon, or two bars.
struct ActivityGlyph: View {
    let activity: MapActivity
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().fill(.white)
            Circle().strokeBorder(GardenStyle.lightLine, lineWidth: 1)
            if let game = activity.gameKind {
                GameIcon(game: game, size: size * 0.78)
            } else if case .placeValue = activity {
                BlockGlyph(tint: activity.tint, size: size * 0.6)
            } else if case .balance = activity {
                BalanceGlyph(tint: activity.tint, size: size * 0.62)
            } else {
                BarGlyph(tint: activity.tint, size: size * 0.6)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Two trays on a post: the icon of the balance activities.
struct BalanceGlyph: View {
    let tint: Color
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(tint)
                .frame(width: size * 0.12, height: size * 0.7)
                .offset(y: size * 0.1)
            Capsule()
                .fill(tint)
                .frame(width: size, height: size * 0.12)
                .offset(y: -size * 0.25)
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(tint.opacity(0.75))
                .frame(width: size * 0.3, height: size * 0.18)
                .offset(x: -size * 0.33, y: -size * 0.08)
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(tint.opacity(0.75))
                .frame(width: size * 0.3, height: size * 0.18)
                .offset(x: size * 0.33, y: -size * 0.08)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A tens rod beside a unit square: the icon of the place-value activities.
struct BlockGlyph: View {
    let tint: Color
    var size: CGFloat = 20

    var body: some View {
        HStack(alignment: .bottom, spacing: size * 0.14) {
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(tint)
                .frame(width: size * 0.3, height: size)
                .overlay {
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle().fill(.white.opacity(0.5)).frame(height: 1)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.top, size * 0.2)
                }
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(tint.opacity(0.75))
                .frame(width: size * 0.3, height: size * 0.3)
        }
        .frame(width: size, height: size, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Two short bars side by side: the icon of the bar activities.
struct BarGlyph: View {
    let tint: Color
    var size: CGFloat = 20

    var body: some View {
        HStack(alignment: .bottom, spacing: size * 0.12) {
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(tint)
                .frame(width: size * 0.36, height: size * 0.6)
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(tint.opacity(0.7))
                .frame(width: size * 0.36, height: size)
        }
        .frame(width: size, height: size, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// The home card that opens the map: a small drawn map, the title, the star total.
struct MapCard: View {
    let totalStars: Int
    let maximumStars: Int
    let nextNode: MapNode?

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            MapIcon(size: 78)

            VStack(alignment: .leading, spacing: 8) {
                Text(GameCopy.mapTitle)
                    .font(.garden(.title2, weight: .heavy))
                    .foregroundStyle(GardenStyle.ink)
                Text("Reis fra øy til øy og samle stjerner.")
                    .font(.garden(.body))
                    .foregroundStyle(GardenStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 14) {
                    Label {
                        Text("\(totalStars) av \(maximumStars)")
                            .font(.garden(.subheadline, weight: .bold))
                            .foregroundStyle(GardenStyle.ink)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "star.fill")
                            .foregroundStyle(GardenStyle.orange)
                    }
                    if let nextNode {
                        Label {
                            Text("Neste: \(nextNode.number)")
                                .font(.garden(.subheadline, weight: .bold))
                                .foregroundStyle(GardenStyle.ink)
                        } icon: {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(GardenStyle.blue)
                        }
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(GardenStyle.blue)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(GardenStyle.lightLine, lineWidth: 1.1)
        }
    }
}

/// Three small islands in a pond with a dotted path between them: the map's own icon.
struct MapIcon: View {
    var size: CGFloat = 66

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.29)
                .fill(GardenStyle.skyTop.opacity(0.7))
            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let islands = [CGPoint(x: 0.26 * w, y: 0.62 * h), CGPoint(x: 0.56 * w, y: 0.36 * h), CGPoint(x: 0.78 * w, y: 0.68 * h)]
                var path = Path()
                path.move(to: islands[0])
                path.addLine(to: islands[1])
                path.addLine(to: islands[2])
                context.stroke(path, with: .color(GardenStyle.sandDeep.opacity(0.8)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [0.1, 6]))
                for (index, centre) in islands.enumerated() {
                    let radius = w * (index == 1 ? 0.15 : 0.13)
                    let rim = CGRect(x: centre.x - radius - 2, y: centre.y - radius * 0.7 - 2, width: 2 * radius + 4, height: 1.4 * radius + 4)
                    context.fill(Path(ellipseIn: rim), with: .color(GardenStyle.sand))
                    let grass = CGRect(x: centre.x - radius, y: centre.y - radius * 0.7, width: 2 * radius, height: 1.4 * radius)
                    context.fill(Path(ellipseIn: grass), with: .color(index == 1 ? GardenStyle.hillNear : GardenStyle.hillMid))
                }
            }
            .padding(size * 0.1)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
