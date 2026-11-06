import SwiftUI

/// Shows a quantity as countable dots in rows of five. Every two rows form a group of ten with
/// a slightly larger gap, so 10, 20, 30 and 40 are easy to recognize at a glance.
/// Several segments can share one frame (for example 18 teal dots followed by 22 orange dots),
/// and `placeholders` draws empty, dashed slots after the filled dots to show a missing amount.
struct BeadGroup: View {
    struct Segment {
        let count: Int
        let tint: Color
    }

    let segments: [Segment]
    let placeholders: Int
    let diameter: CGFloat
    let maxColumns: Int

    /// Gap between dots, proportional to their size so small dots stay readable as a group.
    private var spacing: CGFloat { max(3, diameter * 0.3) }

    init(count: Int, tint: Color, diameter: CGFloat = 22, maxColumns: Int = 5, placeholders: Int = 0) {
        self.init(
            segments: [Segment(count: count, tint: tint)],
            placeholders: placeholders,
            diameter: diameter,
            maxColumns: maxColumns
        )
    }

    init(segments: [Segment], placeholders: Int = 0, diameter: CGFloat = 22, maxColumns: Int = 5) {
        self.segments = segments
        self.placeholders = max(0, placeholders)
        self.diameter = diameter
        self.maxColumns = max(1, maxColumns)
    }

    private var filled: Int { segments.reduce(0) { $0 + max(0, $1.count) } }
    private var total: Int { filled + placeholders }
    private var columns: Int { min(max(total, 1), maxColumns) }
    private var rows: Int { total == 0 ? 0 : (total + columns - 1) / columns }
    private var rowsPerTen: Int { max(1, 10 / columns) }
    private var tenGap: CGFloat { diameter * 0.45 }
    private var width: CGFloat { CGFloat(columns) * diameter + CGFloat(columns - 1) * spacing }
    private var contentHeight: CGFloat {
        guard rows > 0 else { return 0 }
        let tenGaps = (rows - 1) / rowsPerTen
        return CGFloat(rows) * diameter + CGFloat(rows - 1) * spacing + CGFloat(tenGaps) * tenGap
    }

    /// The height a frame of `count` dots occupies. Screens whose quantities change while the
    /// child taps reserve the height of the largest possible amount, so controls never move
    /// under a finger.
    static func height(forCount count: Int, diameter: CGFloat = 22, maxColumns: Int = 5) -> CGFloat {
        BeadGroup(count: max(count, 0), tint: .clear, diameter: diameter, maxColumns: maxColumns).contentHeight
    }

    /// The width a frame of `count` dots occupies (at most `maxColumns` across).
    static func width(forCount count: Int, diameter: CGFloat = 22, maxColumns: Int = 5) -> CGFloat {
        BeadGroup(count: max(count, 0), tint: .clear, diameter: diameter, maxColumns: maxColumns).width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(indices(in: row), id: \.self) { index in
                        dot(at: index)
                    }
                }
                .padding(.top, row > 0 && row % rowsPerTen == 0 ? tenGap : 0)
            }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func indices(in row: Int) -> Range<Int> {
        (row * columns)..<min((row + 1) * columns, total)
    }

    private func tint(at index: Int) -> Color? {
        var start = 0
        for segment in segments {
            let count = max(0, segment.count)
            if index < start + count { return segment.tint }
            start += count
        }
        return nil
    }

    @ViewBuilder
    private func dot(at index: Int) -> some View {
        if let tint = tint(at: index) {
            Circle()
                .fill(tint.gradient)
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1.5)
                }
                .frame(width: diameter, height: diameter)
        } else {
            Circle()
                .strokeBorder(
                    GardenStyle.muted.opacity(0.8),
                    style: StrokeStyle(lineWidth: 2, dash: [3, 2.5])
                )
                .frame(width: diameter, height: diameter)
        }
    }

    private var accessibilityText: String {
        if placeholders > 0 {
            return "\(GameCopy.dots(filled)). Tomme plasser opp til \(total)."
        }
        let parts = segments.filter { $0.count > 0 }.map { GameCopy.dots($0.count) }
        if parts.count > 1 {
            return parts.joined(separator: " og ") + ", \(total) til sammen"
        }
        return GameCopy.dots(filled)
    }
}

struct WhitePanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
            }
    }
}

/// Full-width primary action, comfortably taller than 44 pt for small hands.
struct BigActionButton: View {
    let label: String
    let symbol: String
    let tint: Color
    var identifier: String? = nil
    var hint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .font(.garden(.title3, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundStyle(.white)
                .background(tint, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityHint(hint ?? "")
        .accessibilityIdentifier(identifier ?? "")
    }
}

/// Secondary action (hint, start over) with a generous capsule hit area. While `isSpeaking`
/// is true the symbol's waves pulse (read-aloud buttons), unless Reduce Motion is on.
struct SecondaryActionButton: View {
    let label: String
    let symbol: String
    let tint: Color
    var identifier: String? = nil
    var isSpeaking: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .symbolEffect(.variableColor.iterative.reversing, isActive: isSpeaking && !reduceMotion)
                .font(.garden(.body, weight: .bold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(tint)
                .padding(.horizontal, 20)
                .frame(minHeight: 50)
                .background(.white, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
                }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityIdentifier(identifier ?? "")
    }
}

/// A plus or minus style control. `title` is shown next to the symbol when given;
/// `accessibilityLabel` always describes what the button changes.
struct StepButton: View {
    let symbol: String
    var title: String? = nil
    let tint: Color
    let isEnabled: Bool
    let accessibilityLabel: String
    var identifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 25, weight: .heavy))
                if let title {
                    Text(title)
                        .font(.garden(.body, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(tint)
            .background(tint.opacity(isEnabled ? 0.12 : 0.05), in: RoundedRectangle(cornerRadius: 16))
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier ?? "")
    }
}

/// A number with its dots, used both as a selectable piece and as an answer choice.
/// `isTried` marks an answer the child already tried: dimmed a little and captioned,
/// so the state does not depend on faintness alone.
struct NumberPieceCard: View {
    let number: Int
    let tint: Color
    var compact: Bool = false
    /// Dots per row; rows of ten keep 10-column frames narrow enough for the card grid.
    var columns: Int = 5
    var accessibilityLabel: String? = nil
    var isTried: Bool = false

    private var beadDiameter: CGFloat {
        columns > 5 ? 10 : (compact ? 12 : 15)
    }

    var body: some View {
        VStack(spacing: compact ? 8 : 13) {
            Text("\(number)")
                .font(.display(compact ? 30 : 42))
                .monospacedDigit()
                .foregroundStyle(GardenStyle.ink)
                .opacity(isTried ? 0.65 : 1)
            BeadGroup(count: number, tint: tint, diameter: beadDiameter, maxColumns: columns)
                .opacity(isTried ? 0.65 : 1)
            if isTried {
                // Full opacity: this caption is the readable, non-colour cue.
                Label("Prøvd", systemImage: "xmark.circle")
                    .font(.garden(.footnote, weight: .bold))
                    .foregroundStyle(GardenStyle.ink)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 94 : 132, alignment: .top)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel ?? "Tallbrikke \(number)")
    }
}

/// Always-visible sound control pinned to the bottom of every screen. A white capsule with a
/// speaker means sound is on; a grey capsule with a slashed speaker means it is off.
struct SoundToggleButton: View {
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(Motion.quick(reduceMotion)) {
                voice.toggle()
            }
            if !voice {
                NorwegianVoice.shared.stop()
            }
            TouchFeedback.light()
        } label: {
            Label(voice ? "Lyd på" : "Lyd av", systemImage: voice ? "speaker.wave.2.fill" : "speaker.slash.fill")
                // The speaker swaps with the native symbol transition (instant under Reduce Motion).
                .contentTransition(.symbolEffect(.replace))
                .font(.garden(.body, weight: .bold))
                .lineLimit(1)
                .foregroundStyle(voice ? GardenStyle.ink : .white)
                .padding(.horizontal, 24)
                .frame(minHeight: 56)
                .background(voice ? Color.white : GardenStyle.muted, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
                }
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel(voice ? "Lyd er på" : "Lyd er av")
        .accessibilityHint(voice ? "Trykk for å slå av lyden" : "Trykk for å slå på lyden")
        .accessibilityIdentifier("sound.toggle")
    }
}

/// Glow for the menu choice that is being read aloud, so the child sees which card the
/// voice is describing. Scale is skipped under Reduce Motion; the border and halo remain.
struct NarrationGlow: ViewModifier {
    let isActive: Bool
    let tint: Color
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(tint, lineWidth: isActive ? 5 : 0)
            }
            .shadow(color: isActive ? tint.opacity(0.5) : .clear, radius: isActive ? 20 : 0)
            .scaleEffect(isActive && !reduceMotion ? 1.03 : 1)
            .animation(Motion.quick(reduceMotion), value: isActive)
    }
}

extension View {
    func narrationGlow(_ isActive: Bool, tint: Color, cornerRadius: CGFloat = 28) -> some View {
        modifier(NarrationGlow(isActive: isActive, tint: tint, cornerRadius: cornerRadius))
    }
}

/// Feedback banner. Success is shown with a check mark and tint; guidance with a bulb,
/// so the state never depends on color alone.
struct StatusMessage: View {
    let text: String
    let isSuccess: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Ink for the sentence keeps the text above 4.5:1 on the tinted banner;
        // the symbol carries the colour.
        Label {
            Text(text)
                .foregroundStyle(GardenStyle.ink)
        } icon: {
            icon
        }
            .font(.garden(.title3, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                isSuccess ? GardenStyle.teal.opacity(0.10) : GardenStyle.yellow.opacity(0.24),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityIdentifier("game.feedback")
    }

    /// Bounces once per new success sentence; wiggles (iOS 18) or bounces (iOS 17) once per
    /// new hint. Plain under Reduce Motion.
    @ViewBuilder
    private var icon: some View {
        let image = Image(systemName: isSuccess ? "checkmark.circle.fill" : "lightbulb.fill")
            .foregroundStyle(isSuccess ? GardenStyle.teal : GardenStyle.ink)
        if reduceMotion {
            image
        } else if isSuccess {
            image.symbolEffect(.bounce, value: text)
        } else if #available(iOS 18, *) {
            image.symbolEffect(.wiggle, value: text)
        } else {
            image.symbolEffect(.bounce, value: text)
        }
    }
}

/// Common frame for every activity: the game's garden backdrop (paper with a sky band and a
/// corner sun), back button, title row with the activity's guide creature, and scrolling
/// content. The creature's mood follows the puzzle state and a small flower sprouts at its
/// feet while the puzzle is solved. Every call site compiles unchanged: the creature,
/// mood and progress parameters are optional.
struct GameScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    let tint: Color
    let creature: GardenCreature?
    let mood: CreatureMood
    /// 0...1: the snail turns its shell dial with it, the hedgehog sniffs on every change.
    let progress: Double
    let content: Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Set while the activity plays inside a map node: the title row gives way to the strip.
    @Environment(\.challengeHost) private var challengeHost

    init(
        title: String,
        subtitle: String,
        tint: Color,
        creature: GardenCreature? = nil,
        mood: CreatureMood = .idle,
        progress: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.creature = creature
        self.mood = mood
        self.progress = progress
        self.content = content()
    }

    /// The guide is shown only where the title keeps its full width: regular widths below
    /// the accessibility text sizes. Nothing in Split View, Slide Over or at huge text.
    private var showsCreature: Bool {
        creature != nil && horizontalSizeClass == .regular && dynamicTypeSize < .xxLarge
    }

    var body: some View {
        ZStack {
            GardenBackground(style: .game(tint))

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    if let challengeHost {
                        // Inside a map node: the minimal status strip (back to the map, node
                        // number, one leaf per task, the guide) replaces the title row.
                        ChallengeStatusStrip(
                            host: challengeHost,
                            tint: tint,
                            creature: creature,
                            mood: mood,
                            progress: progress
                        )
                    } else {
                        HStack {
                            Button {
                                NorwegianVoice.shared.stop()
                                dismiss()
                            } label: {
                                Label("Tilbake", systemImage: "arrow.left")
                                    .font(.garden(.body, weight: .bold))
                                    .foregroundStyle(GardenStyle.ink)
                                    .padding(.horizontal, 17)
                                    .frame(minHeight: 48)
                                    .background(.white, in: Capsule())
                                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .accessibilityHint("Går tilbake til startsiden")
                            .accessibilityIdentifier("game.back")

                            Spacer()

                            Text("TALLHAGEN")
                                .font(.display(16))
                                .tracking(2)
                                .foregroundStyle(GardenStyle.muted)
                                .accessibilityHidden(true)
                        }

                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(title)
                                    .font(.display(42))
                                    .foregroundStyle(GardenStyle.ink)
                                    .minimumScaleFactor(0.75)
                                    .lineLimit(1)
                                    .accessibilityAddTraits(.isHeader)
                                    .accessibilityIdentifier("game.title")
                                Text(subtitle)
                                    .font(.garden(.title3))
                                    .foregroundStyle(GardenStyle.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if showsCreature, let creature {
                                Spacer(minLength: 0)
                                guide(creature)
                            }
                        }
                    }

                    content
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 23)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
        }
        .footerClearance()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// The guide beside the title. While the puzzle is solved a small flower in the game's
    /// colour grows at its feet and leaves with the next puzzle (never for the hedgehog:
    /// the workshop has no tasks to reward).
    private func guide(_ creature: GardenCreature) -> some View {
        ZStack(alignment: .bottomLeading) {
            CreatureView(creature: creature, mood: mood, size: 88)
                .environment(\.creatureProgress, progress)
            if mood == .happy && creature != .hedgehog {
                GardenFlower(tint: tint.opacity(0.7), size: 26)
                    .offset(x: 2, y: 2)
                    .transition(.scale(scale: 0.1, anchor: .bottom).combined(with: .opacity))
            }
        }
        .animation(Motion.spring(reduceMotion), value: mood == .happy)
        .accessibilityHidden(true)
    }
}

/// Keeps a pushed screen's content clear of the grass footer. The footer is a safe-area inset
/// on the navigation stack, which the root screen honours, but screens pushed inside the stack
/// receive only the system safe area, so their scroll views would end under the grass. The
/// modifier reads the inset the screen actually received and adds the footer's height when it
/// is missing (never twice).
struct FooterClearance: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .safeAreaPadding(.bottom, proxy.safeAreaInsets.bottom >= GardenTuning.footerHeight ? 0 : GardenTuning.footerHeight)
        }
    }
}

extension View {
    func footerClearance() -> some View {
        modifier(FooterClearance())
    }
}

/// Grass strip pinned under every screen as a safe-area inset. It carries the sound button,
/// its only accessible element, on an opaque meadow with a few flowers at the sides (never
/// under the button) and fills the home-indicator area with grass.
struct GardenFooter<Content: View>: View {
    let content: Content

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            // A darker ground ellipse gives the white capsule an edge on the grass
            // (white on the near grass alone is only 2.13:1).
            .background(alignment: .bottom) {
                Ellipse()
                    .fill(GardenStyle.leaf.opacity(0.45))
                    .frame(height: 14)
                    .padding(.horizontal, -8)
                    .offset(y: 6)
                    .blur(radius: 4)
                    .accessibilityHidden(true)
            }
            .padding(.top, 26)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background {
                ZStack(alignment: .bottom) {
                    GardenMeadow(bloomCount: 0)
                    sideFlowers
                }
                .ignoresSafeArea(edges: .bottom)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
    }

    /// Three flowers in each corner at regular widths, one at compact widths; the centre of
    /// the strip, where the sound capsule rests, never holds a flower.
    private var sideFlowers: some View {
        HStack(alignment: .bottom, spacing: 0) {
            flowerCluster
            Spacer(minLength: 0)
            flowerCluster
                .scaleEffect(x: -1, y: 1, anchor: .center)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private var flowerCluster: some View {
        if horizontalSizeClass == .compact {
            GardenFlower(tint: GardenStyle.petalPink, size: 28)
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                GardenFlower(tint: GardenStyle.petalPink, size: 34)
                GardenFlower(tint: GardenStyle.sunGlow, size: 28)
                GardenFlower(tint: GardenStyle.lilac, size: 32)
            }
        }
    }
}
