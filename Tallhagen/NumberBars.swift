import SwiftUI

// Tallstolpene: the number bars 1–10 and the two bar activities of the island map. A bar is
// `BarMetrics.width` wide and `value × BarMetrics.unit` tall on a unit grid, in its own deep
// colour with a simple face in its top unit, so height, unit lines, colour and character all
// say the same number. Totals above ten stand as tens rods beside a unit bar. The rules live in
// MathLogic.swift (`BarRules`, `BarPuzzle`) and the state in GameSessions.swift (`BarSession`);
// this file adds layout, the tap, drag and swipe gestures, the animations (all skipped under
// Reduce Motion) and speech. The bars are original characters: plain rounded columns with dot
// eyes and a line mouth, no limbs, no numerals with faces, no third-party likeness.

enum BarMetrics {
    /// Height of one unit.
    static let unit: CGFloat = 22
    static let width: CGFloat = 50
    /// Distance between shelf slots.
    static let slotPitch: CGFloat = 66
    static let maximumHeight: CGFloat = unit * CGFloat(BarRules.maximumBarValue)
    /// Hit areas are 20 % larger than the drawing: 10 % of the width on every side.
    static let hitMargin: CGFloat = width * 0.1
    /// No bar is harder to touch than an important control: the short bars (only the 1-bar)
    /// get extra touch area above them, where the shelf is empty.
    static let minimumHitHeight: CGFloat = 48
    /// Touch band of one cut marker: exactly one unit tall, so neighbouring markers never
    /// share a touch, and wider than the drawn disc.
    static let cutMarkerHit = CGSize(width: 36, height: unit)

    static func height(_ value: Int) -> CGFloat {
        CGFloat(max(1, value)) * unit
    }

    /// Extra touch height above a bar of `value` so that its hit area reaches 48 pt.
    static func extraTopHit(_ value: Int) -> CGFloat {
        max(0, minimumHitHeight - (height(value) + 2 * hitMargin))
    }

    /// The touch and drop area of a bar drawn in `frame`: the margin on every side plus the
    /// extra height above short bars.
    static func hitFrame(for frame: CGRect, value: Int) -> CGRect {
        let extra = extraTopHit(value)
        return CGRect(
            x: frame.minX - hitMargin,
            y: frame.minY - hitMargin - extra,
            width: frame.width + 2 * hitMargin,
            height: frame.height + 2 * hitMargin + extra
        )
    }

    /// Rounded top, nearly square foot: the bar stands on the ground line.
    static var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 11, bottomLeadingRadius: 5, bottomTrailingRadius: 5, topTrailingRadius: 11, style: .continuous)
    }
}

/// Ten deep, distinct colours, one per value. White on each of them measures at least 4.6:1
/// (relative luminance 0.17 or lower), so the opaque numeral stays readable; the tens rod is
/// soil brown with golden unit lines.
enum BarPalette {
    static let colours: [Color] = [
        Color(red: 0.76, green: 0.22, blue: 0.30),
        Color(red: 0.74, green: 0.33, blue: 0.10),
        Color(red: 0.52, green: 0.44, blue: 0.08),
        Color(red: 0.18, green: 0.50, blue: 0.27),
        GardenStyle.teal,
        GardenStyle.blue,
        Color(red: 0.30, green: 0.32, blue: 0.75),
        GardenStyle.purple,
        Color(red: 0.68, green: 0.24, blue: 0.55),
        Color(red: 0.45, green: 0.30, blue: 0.17),
    ]

    static func colour(for value: Int) -> Color {
        colours[min(max(value, 1), colours.count) - 1]
    }
}

/// The face of a bar: one expression per value, built from a few shapes.
struct BarFace {
    enum Eyes {
        case open, wide, lidded, wink, sideways, sleepy, glasses, glint
    }

    enum Mouth {
        case round, smile, openSmile, flat, bigSmile, smirk, wide
    }

    let eyes: Eyes
    let mouth: Mouth
    let brows: Bool
    let cheeks: Bool

    static func face(for value: Int) -> BarFace {
        switch value {
        case 1: return BarFace(eyes: .open, mouth: .round, brows: false, cheeks: false)
        case 2: return BarFace(eyes: .lidded, mouth: .smile, brows: false, cheeks: true)
        case 3: return BarFace(eyes: .wide, mouth: .openSmile, brows: false, cheeks: false)
        case 4: return BarFace(eyes: .open, mouth: .flat, brows: true, cheeks: false)
        case 5: return BarFace(eyes: .open, mouth: .bigSmile, brows: true, cheeks: true)
        case 6: return BarFace(eyes: .wink, mouth: .smile, brows: false, cheeks: false)
        case 7: return BarFace(eyes: .sideways, mouth: .smirk, brows: false, cheeks: false)
        case 8: return BarFace(eyes: .glasses, mouth: .smile, brows: false, cheeks: false)
        case 9: return BarFace(eyes: .sleepy, mouth: .smile, brows: false, cheeks: true)
        default: return BarFace(eyes: .glint, mouth: .wide, brows: true, cheeks: true)
        }
    }
}

/// Draws a face into the top unit of a bar (50 x 22 points). `compact` moves the face to the
/// left so the 1-bar has room for its small numeral.
private struct BarFaceView: View {
    let face: BarFace
    let compact: Bool

    private let paper = Color.white.opacity(0.95)
    private var shift: CGFloat { compact ? -8 : 0 }
    private var leftEye: CGPoint { CGPoint(x: 17 + shift, y: 9) }
    private var rightEye: CGPoint { CGPoint(x: 33 + shift, y: 9) }
    private var mouthCentre: CGFloat { 25 + shift }

    var body: some View {
        ZStack {
            eye(at: leftEye, left: true)
            eye(at: rightEye, left: false)
            if face.brows {
                brow(at: leftEye)
                brow(at: rightEye)
            }
            if face.cheeks, !compact {
                Circle().fill(GardenStyle.petalPink.opacity(0.75)).frame(width: 5, height: 5).position(x: 8, y: 14)
                Circle().fill(GardenStyle.petalPink.opacity(0.75)).frame(width: 5, height: 5).position(x: 42, y: 14)
            }
            mouth
        }
        .frame(width: BarMetrics.width, height: BarMetrics.unit)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func eye(at point: CGPoint, left: Bool) -> some View {
        switch face.eyes {
        case .open:
            openEye(at: point, diameter: 8.5, pupilShift: 0, glint: false)
        case .wide:
            openEye(at: point, diameter: 10, pupilShift: 0, glint: false)
        case .glint:
            openEye(at: point, diameter: 8.5, pupilShift: 0, glint: true)
        case .sideways:
            openEye(at: point, diameter: 8.5, pupilShift: 2.2, glint: false)
        case .lidded:
            ZStack {
                Circle().trim(from: 0, to: 0.5).fill(paper).frame(width: 9, height: 9)
                Circle().fill(GardenStyle.ink).frame(width: 3.6, height: 3.6).offset(y: 1.8)
            }
            .position(point)
        case .wink:
            if left {
                arcEye(at: point, upward: true)
            } else {
                openEye(at: point, diameter: 8.5, pupilShift: 0, glint: false)
            }
        case .sleepy:
            arcEye(at: point, upward: false)
        case .glasses:
            ZStack {
                Circle().strokeBorder(paper, lineWidth: 1.6).frame(width: 13, height: 13)
                Circle().fill(paper).frame(width: 7, height: 7)
                Circle().fill(GardenStyle.ink).frame(width: 3.4, height: 3.4)
            }
            .position(point)
            if left {
                Rectangle().fill(paper).frame(width: 4, height: 1.6).position(x: 25 + shift, y: point.y)
            }
        }
    }

    private func openEye(at point: CGPoint, diameter: CGFloat, pupilShift: CGFloat, glint: Bool) -> some View {
        ZStack {
            Circle().fill(paper).frame(width: diameter, height: diameter)
            Circle().fill(GardenStyle.ink).frame(width: diameter * 0.46, height: diameter * 0.46).offset(x: pupilShift)
            if glint {
                Circle().fill(paper).frame(width: 1.6, height: 1.6).offset(x: pupilShift + 1, y: -1)
            }
        }
        .position(point)
    }

    /// A closed eye: an arc that smiles (wink) or droops (sleepy).
    private func arcEye(at point: CGPoint, upward: Bool) -> some View {
        Path { path in
            path.move(to: CGPoint(x: -4.5, y: 0))
            path.addQuadCurve(to: CGPoint(x: 4.5, y: 0), control: CGPoint(x: 0, y: upward ? -4.5 : 4.5))
        }
        .stroke(paper, style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
        .frame(width: 10, height: 10)
        .position(point)
    }

    private func brow(at point: CGPoint) -> some View {
        Capsule().fill(paper).frame(width: 7, height: 1.8).position(x: point.x, y: point.y - 7)
    }

    @ViewBuilder
    private var mouth: some View {
        switch face.mouth {
        case .round:
            Circle().strokeBorder(paper, lineWidth: 1.8).frame(width: 6, height: 6).position(x: mouthCentre, y: 17)
        case .flat:
            Capsule().fill(paper).frame(width: 9, height: 1.8).position(x: mouthCentre, y: 17)
        case .openSmile:
            Circle().trim(from: 0, to: 0.5).fill(paper).frame(width: 11, height: 11).position(x: mouthCentre, y: 15)
        case .smile:
            mouthCurve(halfWidth: 5, depth: 3.5)
        case .bigSmile:
            mouthCurve(halfWidth: 8, depth: 5.5)
        case .wide:
            ZStack {
                Circle().trim(from: 0, to: 0.5).fill(paper).frame(width: 14, height: 14).position(x: mouthCentre, y: 14.5)
                mouthCurve(halfWidth: 7, depth: 0.1)
            }
        case .smirk:
            Path { path in
                path.move(to: CGPoint(x: -4, y: 1))
                path.addQuadCurve(to: CGPoint(x: 6, y: -2), control: CGPoint(x: 2, y: 3))
            }
            .stroke(paper, style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
            .frame(width: 12, height: 8)
            .position(x: mouthCentre, y: 17)
        }
    }

    private func mouthCurve(halfWidth: CGFloat, depth: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: -halfWidth, y: 0))
            path.addQuadCurve(to: CGPoint(x: halfWidth, y: 0), control: CGPoint(x: 0, y: depth * 2))
        }
        .stroke(paper, style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
        .frame(width: halfWidth * 2 + 2, height: depth + 2)
        .position(x: mouthCentre, y: 16)
    }
}

/// One bar: a column `value` units tall with its unit lines, colour, face and optional white
/// numeral. `isGhost` draws only a dashed outline (the target in the building zone).
struct NumberBarView: View {
    let value: Int
    var numeralOpacity: Double = 1
    var isGhost = false
    var ghostTint: Color = GardenStyle.muted

    private var height: CGFloat { BarMetrics.height(value) }
    private var isRod: Bool { value == BarRules.maximumBarValue }

    var body: some View {
        ZStack(alignment: .top) {
            if isGhost {
                BarMetrics.shape
                    .strokeBorder(ghostTint, style: StrokeStyle(lineWidth: 2.5, dash: [7, 5]))
                unitLines(colour: ghostTint.opacity(0.55), dashed: true)
            } else {
                BarMetrics.shape
                    .fill(BarPalette.colour(for: value))
                unitLines(colour: isRod ? GardenStyle.sunGlow.opacity(0.85) : Color.white.opacity(0.32), dashed: false)
                BarMetrics.shape
                    .strokeBorder(GardenStyle.ink.opacity(0.28), lineWidth: 1.5)
                BarFaceView(face: .face(for: value), compact: value == 1)
                numeral
            }
        }
        .frame(width: BarMetrics.width, height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isGhost ? "Mål \(value)" : "Stolpe \(value)")
    }

    private func unitLines(colour: Color, dashed: Bool) -> some View {
        Path { path in
            for index in 1..<max(value, 1) {
                let y = CGFloat(index) * BarMetrics.unit
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: BarMetrics.width, y: y))
            }
        }
        .stroke(colour, style: StrokeStyle(lineWidth: isRod ? 2 : 1.2, dash: dashed ? [4, 4] : []))
    }

    /// White with a dark halo so it reads on every bar colour; faded by the node's range
    /// (`BarRules.numeralOpacity`). Decorative reinforcement: the label and the unit lines
    /// carry the value, so a faint numeral never has to be read.
    @ViewBuilder
    private var numeral: some View {
        if numeralOpacity > 0 {
            Text("\(value)")
                .font(.display(value == 1 ? 12 : (value == 2 ? 16 : 19)))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: GardenStyle.ink.opacity(0.9), radius: 1)
                .shadow(color: GardenStyle.ink.opacity(0.6), radius: 2)
                .frame(width: BarMetrics.width, alignment: value == 1 ? .trailing : .center)
                .padding(.trailing, value == 1 ? 5 : 0)
                .offset(y: value == 1 ? 4 : BarMetrics.unit + (value == 2 ? 1 : 2))
                .opacity(numeralOpacity)
                .accessibilityHidden(true)
        }
    }
}

/// A built total as tens rods beside a unit bar (14 → one rod and a 4-bar), standing on one line.
struct BarComposition: View {
    let total: Int
    var numeralOpacity: Double = 1

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<BarRules.rods(in: total), id: \.self) { _ in
                NumberBarView(value: BarRules.maximumBarValue, numeralOpacity: numeralOpacity)
            }
            if BarRules.units(in: total) > 0 {
                NumberBarView(value: BarRules.units(in: total), numeralOpacity: numeralOpacity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameCopy.barTotal(total))
    }
}

/// The dashed target in the building zone: ghost rods and a ghost unit bar for `total`.
struct BarGhostComposition: View {
    let total: Int
    let tint: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<BarRules.rods(in: total), id: \.self) { _ in
                NumberBarView(value: BarRules.maximumBarValue, isGhost: true, ghostTint: tint)
            }
            if BarRules.units(in: total) > 0 {
                NumberBarView(value: BarRules.units(in: total), isGhost: true, ghostTint: tint)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Side-to-side shake of a refused bar (three cycles per step of `shakes`); the identity when
/// `shakes` is whole, so the bar always comes to rest where it was.
private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 7 * sin(shakes * .pi * 6), y: 0))
    }
}

/// Twelve small capsules that fly out in a ring and fade in 0.55 s when two bars combine.
/// Capsules, not circles, so the burst never looks like counted units. Never created under
/// Reduce Motion (the caller checks) and invisible before the first trigger.
private struct ParticleRing: View {
    let trigger: Int
    let tint: Color

    var body: some View {
        KeyframeAnimator(initialValue: 0.0, trigger: trigger) { progress in
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    let angle = Double(index) * 30 * .pi / 180
                    let distance = 18 + 46 * progress
                    Capsule()
                        .fill(index % 3 == 0 ? GardenStyle.yellow : (index % 3 == 1 ? tint : GardenStyle.petalPink))
                        .frame(width: 5, height: 11)
                        .rotationEffect(.radians(angle + .pi / 2))
                        .scaleEffect(1 - 0.5 * progress)
                        .offset(x: cos(angle) * distance, y: sin(angle) * distance)
                }
            }
            .opacity(trigger == 0 ? 0 : 1 - progress)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(1.0, duration: 0.55)
            }
        }
        .frame(width: 150, height: 150)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// What the finger is doing with a bar: nothing decided yet (a tap if it lifts now), carrying
/// it (any direction) or sweeping sideways to cut. The first 10 points of movement decide:
/// mostly horizontal means a cut. A cut that turns into a long or slow horizontal drag (past
/// one slot, or more than 0.45 s with real travel) becomes a carry, so dragging a bar onto its
/// neighbour never cuts it by accident. The gesture starts on touch-down (no minimum distance)
/// so the scroll view behind the shelf never takes a lifted bar away; taps are therefore
/// recognised here too, as a touch that ends before it moves.
private struct BarDrag {
    enum Mode {
        case pending
        case move
        case cut
    }

    let id: UUID
    var mode: Mode = .pending
    let start = Date()
    var translation: CGSize = .zero
    /// Units below the cut while cutting.
    var cutRow: Int?

    /// True when a sweep has become a carry.
    func shouldBecomeMove(translation: CGSize) -> Bool {
        let dx = abs(translation.width)
        let elapsed = Date().timeIntervalSince(start)
        return dx > BarMetrics.slotPitch || (elapsed > 0.45 && dx > 30)
    }
}

// MARK: - Activity

/// The bar activity of a map node: build a total in the zone (`barBuild`) or cut one bar into
/// two wanted parts (`barSplit`). Tap is a first-class alternative to every gesture: tapping a
/// bar places it (build) or shows its cut markers (split, or a bar too tall for the zone), and
/// the zone takes the last bar back when tapped. The guide is the snail, as in Bygg tallet.
struct BarGameView: View {
    let activity: MapActivity

    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.challengeHost) private var challenge
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: BarSession
    @State private var drag: BarDrag?
    @Environment(\.scenePhase) private var scenePhase
    @State private var shelfFrame: CGRect = .zero
    @State private var zoneFrame: CGRect = .zero
    @State private var hoverTargetID: UUID?
    @State private var isHoveringZone = false
    /// The bar whose cut markers are shown.
    @State private var cutSelection: UUID?
    @State private var shakingID: UUID?
    @State private var shakes: CGFloat = 0
    @State private var squashedID: UUID?
    @State private var flashIDs: Set<UUID> = []
    @State private var recoil: [UUID: CGFloat] = [:]
    @State private var ringTrigger = 0
    @State private var ringCentre: CGPoint = .zero

    private static let playSpace = "barPlay"

    init(activity: MapActivity) {
        self.activity = activity
        _session = State(initialValue: Self.makeSession(for: activity))
    }

    private static func makeSession(for activity: MapActivity) -> BarSession {
        switch activity {
        case .barSplit(let maximum): return BarSession(splitMaximum: maximum)
        default: return BarSession(buildMaximum: activity.maximum)
        }
    }

    private var numeralOpacity: Double { BarRules.numeralOpacity(forMaximum: activity.maximum) }
    private var isBuild: Bool { session.mode == .build }
    private var tint: Color { GardenStyle.blue }

    var body: some View {
        GameScaffold(
            title: "Tallstolpene",
            subtitle: isBuild
                ? "Dra eller trykk på stolper for å bygge tallet på byggeplassen."
                : "Stryk sidelengs over stolpen for å dele den i to.",
            tint: tint,
            creature: .snail,
            mood: session.isSolved ? .happy : (session.hasStarted ? .thinking : .idle),
            progress: isBuild ? Double(session.placedTotal) / Double(max(session.target, 1)) : (session.isSolved ? 1 : 0)
        ) {
            taskPanel
            // Above its scaffold siblings, so a bar carried up or down passes over them.
            playArea.zIndex(1)

            if let feedback = session.feedback {
                StatusMessage(text: feedback, isSuccess: session.isSolved)
            }

            if session.isSolved {
                BigActionButton(
                    label: "Neste oppgave",
                    symbol: "arrow.right.circle.fill",
                    tint: tint,
                    identifier: "game.next",
                    hint: "Lager en ny oppgave",
                    sound: .paper,
                    action: startNewPuzzle
                )
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        readPromptButton
                        hintButton
                        Spacer(minLength: 0)
                        if isBuild { takeBackButton }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        readPromptButton
                        hintButton
                        if isBuild { takeBackButton }
                    }
                }
            }
        }
        .onAppear(perform: speakPromptIfEnabled)
    }

    // MARK: Task

    private var taskPanel: some View {
        WhitePanel {
            VStack(spacing: 10) {
                Text(isBuild ? "Bygg" : "Del stolpen")
                    .font(.garden(.title3, weight: .semibold))
                    .foregroundStyle(GardenStyle.muted)
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(session.target)")
                        .font(.display(64))
                        .foregroundStyle(GardenStyle.purple)
                    if !isBuild {
                        Text("i")
                            .font(.garden(.title2, weight: .semibold))
                            .foregroundStyle(GardenStyle.muted)
                        Text(GameCopy.list(session.wantedParts))
                            .font(.display(44))
                            .foregroundStyle(GardenStyle.teal)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(session.prompt)
                .accessibilityIdentifier("bar.target")
                Text(isBuild ? "med stolpene" : "Begge delene må bli riktige.")
                    .font(.garden(.subheadline, weight: .semibold))
                    .foregroundStyle(GardenStyle.muted)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Play area

    private var playArea: some View {
        ViewThatFits(in: .horizontal) {
            // The shelf draws above the zone, so a carried bar stays on top of the panel it
            // is dropped on (`zIndex` only orders siblings).
            HStack(alignment: .bottom, spacing: 26) {
                shelf.zIndex(1)
                if isBuild { zone }
            }
            VStack(spacing: 22) {
                if isBuild { zone }
                shelf.zIndex(1)
            }
        }
        .frame(maxWidth: .infinity)
        .coordinateSpace(name: Self.playSpace)
    }

    /// Never narrower than the shelf at the start, so placing a bar never re-centres the shelf
    /// (the play area is centred, and a shrinking shelf would move every bar under a finger);
    /// only the bars to the right of the gap close it by one slot.
    private var shelfWidth: CGFloat {
        CGFloat(max(session.shelf.count, session.puzzle.bars.count, 1)) * BarMetrics.slotPitch + 16
    }
    private var shelfHeight: CGFloat { BarMetrics.maximumHeight + 40 }
    private var groundY: CGFloat { shelfHeight - 16 }

    private func slotCentreX(_ index: Int) -> CGFloat {
        8 + BarMetrics.slotPitch * (CGFloat(index) + 0.5)
    }

    /// Frame of the shelf bar at `index`, in the shelf's own coordinates.
    private func barFrame(index: Int, value: Int) -> CGRect {
        let height = BarMetrics.height(value)
        return CGRect(x: slotCentreX(index) - BarMetrics.width / 2, y: groundY - height, width: BarMetrics.width, height: height)
    }

    private var shelf: some View {
        ZStack(alignment: .topLeading) {
            // Faint unit grid behind the bars, so heights can be compared at a glance.
            Path { path in
                for index in 0...BarRules.maximumBarValue {
                    let y = groundY - CGFloat(index) * BarMetrics.unit
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: shelfWidth, y: y))
                }
            }
            .stroke(GardenStyle.lightLine, lineWidth: 1)
            .accessibilityHidden(true)

            Capsule()
                .fill(GardenStyle.soilLight)
                .overlay { Capsule().strokeBorder(GardenStyle.soil, lineWidth: 1) }
                .frame(width: shelfWidth, height: 10)
                .position(x: shelfWidth / 2, y: groundY + 5)
                .accessibilityHidden(true)

            ForEach(Array(session.shelf.enumerated()), id: \.element.id) { index, piece in
                shelfBar(piece, index: index)
            }

            // Cut markers are siblings of the bars, not children, so their taps are never
            // swallowed by the bar's own drag gesture.
            if let selected = cutSelection, !session.isSolved,
               let index = session.shelf.firstIndex(where: { $0.id == selected }) {
                cutMarkers(for: session.shelf[index], frame: barFrame(index: index, value: session.shelf[index].value))
                    .zIndex(20)
            }

            if !reduceMotion {
                ParticleRing(trigger: ringTrigger, tint: tint)
                    .position(ringCentre)
            }
        }
        .frame(width: shelfWidth, height: shelfHeight)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(Self.playSpace))
        } action: { frame in
            shelfFrame = frame
        }
        .animation(Motion.spring(reduceMotion), value: session.shelf.count)
        .onChange(of: scenePhase) { _, phase in
            // A drag the system cancelled (the app went inactive) never reports an end.
            if phase != .active, drag != nil {
                drag = nil
                hoverTargetID = nil
                isHoveringZone = false
            }
        }
    }

    private func shelfBar(_ piece: NumberPiece, index: Int) -> some View {
        let frame = barFrame(index: index, value: piece.value)
        let isDragged = drag?.id == piece.id
        let isMoving = isDragged && drag?.mode == .move
        let translation = isMoving ? (drag?.translation ?? .zero) : .zero
        let isSquashed = squashedID == piece.id
        let extraTop = BarMetrics.extraTopHit(piece.value)
        return NumberBarView(value: piece.value, numeralOpacity: numeralOpacity)
            .overlay(alignment: .top) {
                if isDragged, drag?.mode == .cut, let row = drag?.cutRow {
                    cutLine(at: row, of: piece.value)
                }
            }
            .overlay {
                if flashIDs.contains(piece.id) {
                    BarMetrics.shape.fill(Color.white.opacity(0.8))
                }
            }
            .overlay {
                if hoverTargetID == piece.id {
                    BarMetrics.shape
                        .strokeBorder(tint, style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                        .padding(-5)
                }
            }
            .scaleEffect(x: isSquashed ? 1.18 : 1, y: isSquashed ? 0.82 : 1, anchor: .bottom)
            .scaleEffect(isMoving ? 1.08 : 1)
            .shadow(color: .black.opacity(isMoving ? 0.28 : 0.10), radius: isMoving ? 14 : 3, y: isMoving ? 12 : 2)
            .modifier(ShakeEffect(shakes: shakingID == piece.id ? shakes : 0))
            .padding(BarMetrics.hitMargin)
            .padding(.top, extraTop)
            .contentShape(Rectangle())
            // Starts on touch-down and takes priority, so lifting a bar never scrolls the
            // screen instead; a touch that ends without moving is the tap.
            .highPriorityGesture(dragGesture(for: piece, frame: frame))
            .offset(x: recoil[piece.id] ?? 0)
            // Centred on the hit area, which sits `extraTop` higher than the drawing.
            .position(x: frame.midX, y: frame.midY - extraTop / 2)
            .offset(translation)
            .zIndex(isDragged ? 10 : (cutSelection == piece.id ? 5 : 1))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Stolpe \(piece.value)")
            .accessibilityHint(isBuild ? "Trykk for å sette stolpen på byggeplassen" : "Trykk for å vise delemerkene")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("bar.piece.\(piece.value)")
            .accessibilityActions {
                ForEach(1..<max(piece.value, 1), id: \.self) { bottom in
                    Button("Del i \(bottom) og \(piece.value - bottom)") {
                        split(piece, bottom: bottom)
                    }
                }
            }
    }

    /// The dashed line that follows the finger while cutting.
    private func cutLine(at row: Int, of value: Int) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: BarMetrics.width + 16, height: 3)
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 1.5))
                    path.addLine(to: CGPoint(x: BarMetrics.width + 16, y: 1.5))
                }
                .stroke(GardenStyle.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
            }
            .offset(y: BarMetrics.height(value) - CGFloat(row) * BarMetrics.unit - 1.5)
            .accessibilityHidden(true)
    }

    /// Small round markers at every unit boundary on the right of the selected bar; tapping one
    /// cuts the bar there. The tap alternative to the sideways swipe. Drawn in the shelf's own
    /// coordinates, beside the bar's `frame`. On the 22 pt unit pitch a 48 pt target cannot fit,
    /// so each marker answers in its own one-unit band (`BarMetrics.cutMarkerHit`).
    private func cutMarkers(for piece: NumberPiece, frame: CGRect) -> some View {
        ForEach(1..<max(piece.value, 1), id: \.self) { bottom in
            // The end markers' bands also cover the outer edge of their discs, which no
            // neighbouring band does.
            let overflow = (32 - BarMetrics.cutMarkerHit.height) / 2
            let above = bottom == piece.value - 1 ? overflow : 0
            let below = bottom == 1 ? overflow : 0
            Button {
                split(piece, bottom: bottom)
            } label: {
                Capsule()
                    .fill(GardenStyle.ink)
                    .frame(width: 14, height: 3)
                    .frame(width: 32, height: 32)
                    .background(.white, in: Circle())
                    .overlay { Circle().strokeBorder(tint, lineWidth: 2) }
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    // The disc is drawn larger than its touch band; the bands of neighbouring
                    // markers meet exactly, so a touch always goes to the nearest marker.
                    .frame(width: BarMetrics.cutMarkerHit.width, height: BarMetrics.cutMarkerHit.height)
                    .padding(.top, above)
                    .padding(.bottom, below)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BouncyButtonStyle())
            // Centred so that the disc, not the padded band, sits on the unit boundary.
            .position(x: frame.maxX + 22, y: frame.maxY - CGFloat(bottom) * BarMetrics.unit + (below - above) / 2)
            .accessibilityLabel("Del i \(bottom) og \(piece.value - bottom)")
            .accessibilityIdentifier("bar.cut.\(bottom)")
        }
    }

    private var zoneDragging: Bool { drag?.mode == .move }

    private var zone: some View {
        VStack(spacing: 10) {
            Text("Byggeplassen")
                .font(.garden(.subheadline, weight: .bold))
                .foregroundStyle(GardenStyle.muted)
                .accessibilityHidden(true)

            ZStack(alignment: .bottomLeading) {
                BarGhostComposition(total: session.target, tint: zoneDragging ? tint : GardenStyle.muted.opacity(0.7))
                if session.placedTotal > 0 {
                    BarComposition(total: session.placedTotal, numeralOpacity: numeralOpacity)
                        .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                }
            }
            .frame(minHeight: BarMetrics.maximumHeight + 12, alignment: .bottom)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(isHoveringZone ? tint.opacity(0.10) : Color.white)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        zoneDragging ? tint : GardenStyle.lightLine,
                        style: StrokeStyle(lineWidth: zoneDragging ? 3 : 1.2, dash: zoneDragging ? [10, 6] : [])
                    )
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(GardenStyle.soilLight)
                    .frame(height: 8)
                    .padding(.horizontal, 10)
                    .offset(y: -6)
                    .accessibilityHidden(true)
            }
            .animation(Motion.quick(reduceMotion), value: isHoveringZone)
            .animation(Motion.spring(reduceMotion), value: session.placedTotal)
            .contentShape(Rectangle())
            .onTapGesture(perform: takeBackLast)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(Self.playSpace))
            } action: { frame in
                zoneFrame = frame
            }
            // One element for the drop area; the running total below stays its own element.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Byggeplassen: \(GameCopy.barTotal(session.placedTotal)). Målet er \(session.target).")
            .accessibilityHint("Trykk for å ta tilbake den siste stolpen")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("bar.zone")

            Text("Ditt tall: \(session.placedTotal)")
                .font(.display(26))
                .monospacedDigit()
                .foregroundStyle(GardenStyle.ink)
                .contentTransition(.numericText())
                .accessibilityIdentifier("bar.currentTotal")
        }
    }

    // MARK: Buttons

    private var readPromptButton: some View {
        SecondaryActionButton(
            label: "Les opp oppgaven",
            symbol: "speaker.wave.2.fill",
            tint: tint,
            identifier: "game.readPrompt",
            action: readPromptAloud
        )
    }

    private var hintButton: some View {
        SecondaryActionButton(
            label: "Få et hint",
            symbol: "lightbulb.fill",
            tint: tint,
            identifier: "bar.hint",
            action: showHint
        )
    }

    private var takeBackButton: some View {
        SecondaryActionButton(
            label: "Ta tilbake",
            symbol: "arrow.uturn.backward",
            tint: tint,
            identifier: "bar.takeBack",
            action: takeBackLast
        )
    }

    // MARK: Gestures

    private func dragGesture(for piece: NumberPiece, frame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.playSpace))
            .onChanged { value in
                guard !session.isSolved else { return }
                if drag?.id != piece.id {
                    drag = BarDrag(id: piece.id)
                }
                guard var current = drag else { return }
                let dx = abs(value.translation.width)
                let dy = abs(value.translation.height)
                if current.mode == .pending {
                    // Nothing is decided until the finger has travelled 10 points.
                    guard dx * dx + dy * dy >= 100 else {
                        drag = current
                        return
                    }
                    // A 1-bar has nothing to cut: a sideways sweep carries it instead.
                    current.mode = dx > 2 * dy && piece.value > 1 ? .cut : .move
                    if cutSelection != nil {
                        withAnimation(Motion.quick(reduceMotion)) { cutSelection = nil }
                    }
                }
                if current.mode == .cut, current.shouldBecomeMove(translation: value.translation) {
                    current.mode = .move
                    current.cutRow = nil
                }
                switch current.mode {
                case .pending:
                    break
                case .move:
                    current.translation = value.translation
                    hoverTargetID = dropTarget(for: piece, at: value.location)
                    isHoveringZone = zoneContains(value.location)
                case .cut:
                    let playFrame = frame.offsetBy(dx: shelfFrame.minX, dy: shelfFrame.minY)
                    let unitsBelow = Int(((playFrame.maxY - value.location.y) / BarMetrics.unit).rounded())
                    current.cutRow = min(max(unitsBelow, 1), max(piece.value - 1, 1))
                }
                drag = current
            }
            .onEnded { value in
                guard let current = drag, current.id == piece.id else {
                    drag = nil
                    return
                }
                let target = dropTarget(for: piece, at: value.location)
                let overZone = zoneContains(value.location)
                withAnimation(Motion.spring(reduceMotion)) {
                    drag = nil
                    hoverTargetID = nil
                    isHoveringZone = false
                }
                // The outcome may remove this very bar from the shelf. That happens on the next
                // run-loop turn, after the gesture has fully ended; removing the view inside its
                // own end callback left the scroll view's touch handling stuck on the simulator.
                let horizontal = abs(value.translation.width)
                DispatchQueue.main.async {
                    switch current.mode {
                    case .pending:
                        // Lifted before moving: a tap.
                        tap(piece)
                    case .move:
                        if let target {
                            combine(piece, onto: target)
                        } else if overZone {
                            place(piece)
                        }
                    case .cut:
                        if horizontal >= 28, piece.value > 1, let row = current.cutRow {
                            split(piece, bottom: row)
                        }
                    }
                }
            }
    }

    /// The shelf bar under the finger (the same hit area as a touch: 20 % larger than the
    /// drawing, at least 48 pt tall), other than the one being carried.
    private func dropTarget(for piece: NumberPiece, at location: CGPoint) -> UUID? {
        let local = CGPoint(x: location.x - shelfFrame.minX, y: location.y - shelfFrame.minY)
        for (index, other) in session.shelf.enumerated() where other.id != piece.id {
            let frame = BarMetrics.hitFrame(for: barFrame(index: index, value: other.value), value: other.value)
            if frame.contains(local) { return other.id }
        }
        return nil
    }

    private func zoneContains(_ location: CGPoint) -> Bool {
        guard isBuild, zoneFrame != .zero else { return false }
        return zoneFrame.insetBy(dx: -zoneFrame.width * 0.1, dy: -zoneFrame.height * 0.1).contains(location)
    }

    // MARK: Actions

    private func tap(_ piece: NumberPiece) {
        guard !session.isSolved else { return }
        if isBuild {
            if piece.value > session.remaining {
                // Refused, but the cut markers appear so the bar can be made to fit.
                let outcome = session.place(piece.id)
                reject(piece)
                withAnimation(Motion.quick(reduceMotion)) { cutSelection = piece.id }
                respond(to: outcome)
            } else {
                place(piece)
            }
        } else {
            guard piece.value > 1 else { return }
            withAnimation(Motion.quick(reduceMotion)) {
                cutSelection = cutSelection == piece.id ? nil : piece.id
            }
            SoundCuePlayer.shared.play(.tick, enabled: voice)
        }
    }

    private func place(_ piece: NumberPiece) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.place(piece.id)
        }
        if outcome == .rejected { reject(piece) }
        cutSelection = nil
        respond(to: outcome)
    }

    private func combine(_ piece: NumberPiece, onto targetID: UUID) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.combine(piece.id, onto: targetID)
        }
        if outcome == .rejected {
            reject(piece)
        } else if let combined = session.lastCombined,
                  let slot = session.shelf.firstIndex(where: { $0.id == combined }) {
            // Looked up after the merge: the carried bar has left the shelf, so a bar carried
            // from the left ends one slot further left than its target stood.
            celebrateCombine(combined, slot: slot)
        }
        cutSelection = nil
        respond(to: outcome)
    }

    private func split(_ piece: NumberPiece, bottom: Int) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.split(piece.id, bottom: bottom)
        }
        withAnimation(Motion.quick(reduceMotion)) { cutSelection = nil }
        if outcome == .rejected {
            reject(piece)
        } else if outcome != .ignored {
            animateSplit(session.lastSplit)
        }
        respond(to: outcome)
    }

    private func takeBackLast() {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.takeBackLast()
        }
        guard outcome != .ignored else { return }
        GameFeedback.react(to: .progress, feedback: session.feedback ?? "Stolpen er tilbake på hyllen.", voiceEnabled: voice)
    }

    /// Shake and spring back (haptics and the spoken sentence come from `respond`).
    private func reject(_ piece: NumberPiece) {
        guard !reduceMotion else { return }
        shakingID = piece.id
        withAnimation(.linear(duration: 0.35)) {
            shakes += 1
        }
    }

    /// Squash-and-stretch of the new bar and a particle ring around it.
    private func celebrateCombine(_ id: UUID, slot: Int) {
        guard !reduceMotion else { return }
        let value = session.shelfPiece(id)?.value ?? 1
        let frame = barFrame(index: slot, value: value)
        ringCentre = CGPoint(x: frame.midX, y: frame.midY)
        ringTrigger += 1
        squashedID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                squashedID = nil
            }
        }
    }

    /// A brief white flash on both parts and a small recoil apart.
    private func animateSplit(_ ids: [UUID]) {
        guard !reduceMotion, ids.count == 2 else { return }
        flashIDs = Set(ids)
        recoil = [ids[0]: -9, ids[1]: 9]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                recoil = [:]
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                flashIDs = []
            }
        }
    }

    private func showHint() {
        session.showHint()
        if let feedback = session.feedback {
            VoiceOverAnnouncer.announce(feedback)
            NorwegianVoice.shared.say(feedback, enabled: voice)
        }
    }

    private func readPromptAloud() {
        NorwegianVoice.shared.say(session.prompt, enabled: true, deferToVoiceOver: false)
    }

    private func speakPromptIfEnabled() {
        NorwegianVoice.shared.say(session.prompt, enabled: voice)
    }

    private func startNewPuzzle() {
        withAnimation(Motion.quick(reduceMotion)) {
            session = Self.makeSession(for: activity)
            cutSelection = nil
            drag = nil
            hoverTargetID = nil
            isHoveringZone = false
        }
        speakPromptIfEnabled()
    }

    private func respond(to outcome: AnswerOutcome) {
        if outcome == .solved {
            solvedTotal += 1
        }
        challenge?.report(outcome)
        GameFeedback.react(to: outcome, feedback: session.feedback, voiceEnabled: voice)
    }
}
