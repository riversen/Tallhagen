import SwiftUI

// The four garden guides: original, friendly garden animals drawn from SwiftUI shapes only.
// Pure decoration: every view here is hidden from VoiceOver and touch, never shows text and
// never carries an accessibility identifier. Colour tokens come from `GardenStyle` (Theme.swift
// and the garden palette extension owned by GardenScenery.swift); this file defines none.
//
// Motion contract: idle motion is a pure function of a shared 20 fps clock with the rest pose
// at t = 0, one-shot reactions run through PhaseAnimator / KeyframeAnimator, and under
// Reduce Motion neither a clock nor an animator is created. The only animation that remains
// then is a 0.4 s opacity crossfade of eyes, highlights and halos (`moodCrossfade`).

// MARK: - Catalogue

/// One guide per activity. Working names used in the design notes and in these comments only,
/// never shown or spoken: Rulle the snail, Flagra the butterfly, Summa the bumblebee and
/// Noste the hedgehog.
enum GardenCreature: CaseIterable {
    /// Rulle: builds its house ring by ring; the shell spiral turns like a dial with
    /// `creatureProgress` (Bygg tallet).
    case snail
    /// Flagra: an orange wing pair and a teal wing pair, two parts of one whole, like the given
    /// number and its friend (Finn tallvennen).
    case butterfly
    /// Summa: flies between the left flower and the right flower (Del opp).
    case bee
    /// Noste: a tinkerer with a leaf on its back that sniffs at every plus and minus
    /// (Tallverkstedet); its reaction at the maximum is a tiny, reward-free nod.
    case hedgehog

    /// Bokmål species name, for documentation and any future label. Not displayed today.
    var norwegianName: String {
        switch self {
        case .snail: return "snegl"
        case .butterfly: return "sommerfugl"
        case .bee: return "humle"
        case .hedgehog: return "pinnsvin"
        }
    }

    /// The tint of the game the guide belongs to (halo, burst petals).
    var tint: Color {
        switch self {
        case .snail: return GardenStyle.teal
        case .butterfly: return GardenStyle.orange
        case .bee: return GardenStyle.purple
        case .hedgehog: return GardenStyle.blue
        }
    }

    /// The guide of an activity.
    static func forGame(_ game: GameKind) -> GardenCreature {
        switch game {
        case .build: return .snail
        case .pair: return .butterfly
        case .split: return .bee
        case .workshop: return .hedgehog
        }
    }

    /// Seconds added to the idle clock so guides shown on one screen never move in unison.
    fileprivate var clockOffset: Double {
        0.9 * Double(GardenCreature.allCases.firstIndex(of: self) ?? 0)
    }
}

/// What the guide is doing. `thinking` is the attentive pose while the child works or while
/// a menu card is being narrated; `happy` is held after a solve until the next puzzle.
/// No mood ever reacts to a wrong answer.
enum CreatureMood {
    case idle, happy, thinking
}

/// Optional progress hook (0...1): the snail turns its spiral by `progress` x 360 degrees and
/// the hedgehog sniffs on every change. The default 0 means no dial and no sniff.
struct CreatureProgressKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

extension EnvironmentValues {
    /// See `CreatureProgressKey`. Set with `.environment(\.creatureProgress, value)`.
    var creatureProgress: Double {
        get { self[CreatureProgressKey.self] }
        set { self[CreatureProgressKey.self] = newValue }
    }
}

// MARK: - Shared constants

/// Opacity-only crossfade of eyes, highlights and halos: the single permitted animation under
/// Reduce Motion (motion replaced by a fade).
private let moodCrossfade = Animation.easeInOut(duration: 0.4)

/// Minimum interval of the idle clock (20 fps); a performance lever.
private let idleFrameInterval = 1.0 / 20

// MARK: - CreatureView

/// Draws one guide at `size` points (88 in a game title row, 64 on a home card, 56 on the
/// chooser veil). Idle motion, mood poses and the one-shot happy reaction all live here; the
/// view is decoration only (`accessibilityHidden`, no hit testing).
struct CreatureView: View {
    let creature: GardenCreature
    let mood: CreatureMood
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.creatureProgress) private var progress
    /// Counts transitions into `.happy`; triggers the hop, flight or wing beats and the burst.
    @State private var celebration = 0
    /// Counts progress changes; triggers the hedgehog's sniff.
    @State private var sniffCount = 0
    /// False while another screen covers this one, so a hidden guide does not keep ticking.
    @State private var isOnScreen = true

    init(creature: GardenCreature, mood: CreatureMood, size: CGFloat) {
        self.creature = creature
        self.mood = mood
        self.size = size
    }

    var body: some View {
        ZStack {
            halo
            animatedCreature
            if !reduceMotion && creature != .hedgehog {
                PetalBurst(trigger: celebration, size: size, tint: creature.tint)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: mood) { _, newMood in
            if newMood == .happy { celebration += 1 }
        }
        .onChange(of: progress) { _, _ in
            sniffCount += 1
        }
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var isPaused: Bool { scenePhase != .active || !isOnScreen }

    /// Soft tinted disc behind the guide while it is happy (fade only).
    private var halo: some View {
        Circle()
            .fill(creature.tint.opacity(0.18))
            .frame(width: size * 1.25, height: size * 1.25)
            .opacity(mood == .happy ? 1 : 0)
            .animation(moodCrossfade, value: mood == .happy)
    }

    /// Reduce Motion: the rest drawing, no clock, no animator. Otherwise the one-shot animator
    /// wraps the idle clock, so a celebration pose and the idle sway compose.
    @ViewBuilder
    private var animatedCreature: some View {
        if reduceMotion {
            drawing(t: 0, pose: .rest)
        } else {
            switch creature {
            case .snail, .hedgehog:
                PhaseAnimator(HappyPhase.allCases, trigger: celebration) { phase in
                    clocked { t in
                        drawing(t: t, pose: HappyPose(phase: phase, creature: creature))
                    }
                } animation: { phase in
                    phase.animation
                }
            case .butterfly:
                KeyframeAnimator(initialValue: HappyPose.rest, trigger: celebration) { pose in
                    clocked { t in drawing(t: t, pose: pose) }
                } keyframes: { _ in
                    // Two wing beats at about 2.3 Hz, a rise and a soft settle, a small tilt.
                    KeyframeTrack(\.wing) {
                        CubicKeyframe(0.72, duration: 0.22)
                        CubicKeyframe(1.0, duration: 0.22)
                        CubicKeyframe(0.72, duration: 0.22)
                        CubicKeyframe(1.0, duration: 0.22)
                    }
                    KeyframeTrack(\.lift) {
                        CubicKeyframe(-10, duration: 0.5)
                        SpringKeyframe(0, duration: 0.6)
                    }
                    KeyframeTrack(\.tilt) {
                        CubicKeyframe(6, duration: 0.5)
                        CubicKeyframe(0, duration: 0.6)
                    }
                }
            case .bee:
                KeyframeAnimator(initialValue: HappyPose.rest, trigger: celebration) { pose in
                    clocked { t in drawing(t: t, pose: pose) }
                } keyframes: { _ in
                    // A figure-eight in grid units over 0.9 s with a gentle lean.
                    KeyframeTrack(\.offset) {
                        CubicKeyframe(CGSize(width: -18, height: -10), duration: 0.25)
                        CubicKeyframe(.zero, duration: 0.2)
                        CubicKeyframe(CGSize(width: 18, height: -10), duration: 0.2)
                        CubicKeyframe(.zero, duration: 0.25)
                    }
                    KeyframeTrack(\.tilt) {
                        CubicKeyframe(-8, duration: 0.3)
                        CubicKeyframe(8, duration: 0.3)
                        CubicKeyframe(0, duration: 0.3)
                    }
                }
            }
        }
    }

    /// The idle clock: 20 fps, paused and forced to the rest pose while the scene is inactive.
    private func clocked<Content: View>(@ViewBuilder _ content: @escaping (Double) -> Content) -> some View {
        TimelineView(.animation(minimumInterval: idleFrameInterval, paused: isPaused)) { context in
            content(
                isPaused
                    ? 0
                    : context.date.timeIntervalSinceReferenceDate + creature.clockOffset
            )
        }
    }

    @ViewBuilder
    private func drawing(t: Double, pose: HappyPose) -> some View {
        let grid = DesignGrid(size: size)
        switch creature {
        case .snail:
            SnailDrawing(grid: grid, t: t, mood: mood, progress: progress, turns: celebration,
                         pose: pose, reduceMotion: reduceMotion)
        case .butterfly:
            ButterflyDrawing(grid: grid, t: t, mood: mood, pose: pose, reduceMotion: reduceMotion)
        case .bee:
            BeeDrawing(grid: grid, t: t, mood: mood, pose: pose, reduceMotion: reduceMotion,
                       reduceTransparency: reduceTransparency)
        case .hedgehog:
            HedgehogDrawing(grid: grid, t: t, mood: mood, sniffs: sniffCount, pose: pose,
                            reduceMotion: reduceMotion)
        }
    }
}

// MARK: - One-shot reaction poses

/// Phases of the snail's and the hedgehog's hop: squash, hop, land, back to rest (about 0.7 s).
private enum HappyPhase: CaseIterable {
    case rest, squash, hop, land

    /// Animation used when transitioning into this phase.
    var animation: Animation {
        switch self {
        case .squash: return .easeOut(duration: 0.12)
        case .hop: return .spring(response: 0.35, dampingFraction: 0.6)
        case .land, .rest: return .easeOut(duration: 0.25)
        }
    }
}

/// Everything a celebration can move, in grid units and degrees. The rest value is the identity,
/// so the drawings read the same pose type whether or not an animator is running.
private struct HappyPose {
    /// Squash and stretch about the feet.
    var scale = CGSize(width: 1, height: 1)
    /// Vertical hop (negative is up).
    var lift: CGFloat = 0
    /// Butterfly wing-pair scale (1 = open).
    var wing: CGFloat = 1
    /// Whole-body lean in degrees.
    var tilt: Double = 0
    /// Bee flight path offset.
    var offset: CGSize = .zero
    /// Extra rotation of the hedgehog's leaf.
    var leafTilt: Double = 0

    static let rest = HappyPose()

    init() {}

    init(phase: HappyPhase, creature: GardenCreature) {
        self.init()
        switch (phase, creature) {
        case (.squash, .hedgehog):
            scale = CGSize(width: 1.08, height: 0.9)
        case (.squash, _):
            scale = CGSize(width: 1.06, height: 0.92)
        case (.hop, .hedgehog):
            lift = -8
            leafTilt = -15
        case (.hop, _):
            lift = -14
            scale = CGSize(width: 0.97, height: 1.06)
        case (.rest, _), (.land, _):
            break
        }
    }
}

// MARK: - Design grid helpers

/// Maps the 100 x 100 design grid of the drawing plans onto a view `size` points wide and tall.
/// Every coordinate and dimension in the drawings is written in grid units.
private struct DesignGrid {
    let size: CGFloat

    /// One grid unit in points.
    var u: CGFloat { size / 100 }

    func length(_ units: CGFloat) -> CGFloat { units * u }

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * u, y: y * u) }

    /// Rotation or scale anchor at a grid point of a full-grid layer.
    func anchor(_ x: CGFloat, _ y: CGFloat) -> UnitPoint { UnitPoint(x: x / 100, y: y / 100) }

    /// Standard outline: 1.5 pt at 88 pt, never thinner than 1.2 pt.
    var line: CGFloat { max(1.2, 1.7 * u) }

    /// Heavier rim of the snail shell.
    var rim: CGFloat { max(1.5, 2.3 * u) }

    /// Round-capped stroke of `units` grid units, never thinner than `minimum` points.
    func stroke(_ units: CGFloat, minimum: CGFloat = 1) -> StrokeStyle {
        StrokeStyle(lineWidth: max(minimum, units * u), lineCap: .round, lineJoin: .round)
    }
}

private extension View {
    /// Frames the view in grid units.
    func sized(_ grid: DesignGrid, _ width: CGFloat, _ height: CGFloat) -> some View {
        frame(width: grid.length(width), height: grid.length(height))
    }

    /// Centres the view on a grid point of the enclosing full-grid layer.
    func placedAt(_ grid: DesignGrid, _ x: CGFloat, _ y: CGFloat) -> some View {
        position(grid.point(x, y))
    }

    /// Gives a layer the full grid, so `placedAt` and `grid.anchor` line up.
    func fullGrid(_ grid: DesignGrid) -> some View {
        frame(width: grid.size, height: grid.size)
    }
}

/// Screen-space polar point: 0 degrees points right, 90 down, 270 up.
private func polar(_ centre: CGPoint, _ radius: CGFloat, _ degrees: Double) -> CGPoint {
    let radians = degrees * .pi / 180
    return CGPoint(x: centre.x + radius * CGFloat(cos(radians)), y: centre.y + radius * CGFloat(sin(radians)))
}

/// A shape drawn in grid units and scaled to its frame (always the full grid).
private protocol GridShape: Shape {
    func draw(_ path: inout Path)
}

private extension GridShape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        draw(&path)
        return path.applying(CGAffineTransform(scaleX: rect.width / 100, y: rect.height / 100))
    }
}

/// A single quadratic curve (mouths, antennae).
private struct QuadStroke: GridShape {
    var from: CGPoint
    var control: CGPoint
    var to: CGPoint

    func draw(_ path: inout Path) {
        path.move(to: from)
        path.addQuadCurve(to: to, control: control)
    }
}

/// A straight line in grid units.
private struct GridLine: GridShape {
    var from: CGPoint
    var to: CGPoint

    func draw(_ path: inout Path) {
        path.move(to: from)
        path.addLine(to: to)
    }
}

/// The hedgehog's snout: a soft wedge from the face to the nose tip.
private struct SnoutShape: GridShape {
    func draw(_ path: inout Path) {
        path.move(to: CGPoint(x: 34, y: 66))
        path.addQuadCurve(to: CGPoint(x: 8, y: 76), control: CGPoint(x: 18, y: 64))
        path.addQuadCurve(to: CGPoint(x: 34, y: 84), control: CGPoint(x: 18, y: 86))
        path.closeSubpath()
    }
}

/// The hedgehog's spine coat: a dome of soft zigzag tips from the brow (200 degrees) over the
/// back to the rump (350 degrees), closed along a base that the belly hides.
private struct SpineDome: GridShape {
    var centre: CGPoint
    var peak: CGFloat
    var valley: CGFloat

    func draw(_ path: inout Path) {
        let count = 19
        for index in 0..<count {
            let degrees = 200 + 150 * Double(index) / Double(count - 1)
            let point = polar(centre, index % 2 == 0 ? peak : valley, degrees)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.addLine(to: CGPoint(x: centre.x + valley * 0.8, y: centre.y + 6))
        path.addLine(to: CGPoint(x: centre.x - valley * 0.8, y: centre.y + 6))
        path.closeSubpath()
    }
}

/// An arc centred in its own frame, sampled every few degrees so the direction is never
/// ambiguous (screen angles: 270 is up). Used for happy eyes and the shell highlight.
private struct ArcShape: Shape {
    var radius: CGFloat
    var from: Double
    var to: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let steps = max(4, Int(abs(to - from) / 5))
        for index in 0...steps {
            let degrees = from + (to - from) * Double(index) / Double(steps)
            let point = polar(centre, radius, degrees)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

/// The snail's Archimedean spiral, centred in its frame: r = start + growth x theta, sampled
/// every 6 degrees for `turns` turns. Whatever lies outside the shell is clipped by the caller.
private struct Spiral: Shape {
    var startRadius: CGFloat
    var growth: CGFloat
    var turns: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let steps = Int(turns * 60)
        for index in 0...steps {
            let theta = Double(index) * .pi / 30
            let radius = startRadius + growth * CGFloat(theta)
            let point = CGPoint(x: centre.x + radius * CGFloat(cos(theta)), y: centre.y + radius * CGFloat(sin(theta)))
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

// MARK: - Eyes

private enum CreatureEyes {
    /// One eye: an open pupil crossfaded with a happy arc. The crossfade is opacity only and
    /// runs in every motion setting; the pupil shift of the thinking pose goes through `Motion`.
    struct Eye: View {
        let grid: DesignGrid
        /// Eyeball diameter in grid units (the pupil alone when `ball` is nil).
        var diameter: CGFloat
        var ball: Color? = nil
        var rim: Color? = nil
        var pupil: Color
        var pupilDiameter: CGFloat
        /// Horizontal pupil shift in grid units; negative looks left, towards the task.
        var pupilShift: CGFloat = 0
        var glint = false
        var arc: Color
        var arcWidth: CGFloat
        var arcRadius: CGFloat
        let isHappy: Bool
        let reduceMotion: Bool

        private var side: CGFloat {
            grid.length(max(diameter, 2 * arcRadius + arcWidth))
        }

        var body: some View {
            ZStack {
                openEye
                    .opacity(isHappy ? 0 : 1)
                ArcShape(radius: grid.length(arcRadius), from: 200, to: 340)
                    .stroke(arc, style: grid.stroke(arcWidth))
                    .opacity(isHappy ? 1 : 0)
            }
            .frame(width: side, height: side)
            .animation(moodCrossfade, value: isHappy)
        }

        private var openEye: some View {
            ZStack {
                if let ball {
                    Circle()
                        .fill(ball)
                        .overlay {
                            if let rim {
                                Circle().strokeBorder(rim, lineWidth: max(0.8, grid.u))
                            }
                        }
                        .sized(grid, diameter, diameter)
                }
                ZStack {
                    Circle()
                        .fill(pupil)
                        .sized(grid, pupilDiameter, pupilDiameter)
                    if glint {
                        Circle()
                            .fill(.white)
                            .sized(grid, 1.5, 1.5)
                            .offset(x: grid.length(1), y: -grid.length(1))
                    }
                }
                .offset(x: grid.length(pupilShift))
                .animation(Motion.quick(reduceMotion), value: pupilShift)
            }
        }
    }
}

// MARK: - Snail (Rulle)

/// Faces left. The shell spiral is the dial: it turns by `progress` x 360 degrees and adds one
/// full turn per celebration (never reversing through a reset of the turn count).
private struct SnailDrawing: View {
    let grid: DesignGrid
    let t: Double
    let mood: CreatureMood
    let progress: Double
    let turns: Int
    let pose: HappyPose
    let reduceMotion: Bool

    private var thinking: Bool { mood == .thinking }
    private var happy: Bool { mood == .happy }
    /// Idle stalk sway in degrees (0 at t = 0).
    private var sway: Double { 6 * sin(2 * .pi * t / 5.2) }
    /// Idle breath: a 3 % vertical stretch about the foot.
    private var breath: CGFloat { 1 + 0.03 * CGFloat(sin(2 * .pi * t / 5.2)) }

    var body: some View {
        ZStack {
            shadow
            foot
            head
            stalk(baseX: 16, restAngle: -18, sway: sway)
            stalk(baseX: 26, restAngle: 8, sway: -sway)
            cheek
            mouth
            shell
        }
        .fullGrid(grid)
        .drawingGroup()
        .scaleEffect(x: 1, y: breath, anchor: .bottom)
        .scaleEffect(pose.scale, anchor: .bottom)
        .offset(y: grid.length(pose.lift))
        .offset(y: thinking ? -grid.length(3) : 0)
        .animation(Motion.quick(reduceMotion), value: mood)
    }

    private var shadow: some View {
        Ellipse()
            .fill(GardenStyle.ink.opacity(0.08))
            .sized(grid, 72, 9)
            .placedAt(grid, 52, 90)
    }

    private var foot: some View {
        Capsule()
            .fill(GardenStyle.sand)
            .overlay { Capsule().strokeBorder(GardenStyle.sandDeep, lineWidth: grid.line) }
            .sized(grid, 76, 24)
            .placedAt(grid, 54, 76)
    }

    private var head: some View {
        Circle()
            .fill(GardenStyle.sand)
            .overlay { Circle().strokeBorder(GardenStyle.sandDeep, lineWidth: grid.line) }
            .sized(grid, 30, 30)
            .placedAt(grid, 22, 66)
    }

    /// An eye stalk with its eye, rotating about the stalk's base on the head.
    private func stalk(baseX: CGFloat, restAngle: Double, sway: Double) -> some View {
        ZStack {
            Capsule()
                .fill(GardenStyle.sand)
                .overlay { Capsule().strokeBorder(GardenStyle.sandDeep, lineWidth: grid.line) }
                .sized(grid, 5, 24)
                .placedAt(grid, baseX, 44)
            CreatureEyes.Eye(
                grid: grid,
                diameter: 10,
                ball: .white,
                rim: GardenStyle.sandDeep,
                pupil: GardenStyle.ink,
                pupilDiameter: 4.5,
                pupilShift: thinking ? -2.5 : -1,
                arc: GardenStyle.ink,
                arcWidth: 2.2,
                arcRadius: 4.5,
                isHappy: happy,
                reduceMotion: reduceMotion
            )
            .placedAt(grid, baseX, 32)
        }
        .fullGrid(grid)
        .rotationEffect(.degrees(sway), anchor: grid.anchor(baseX, 56))
        .rotationEffect(.degrees(restAngle + (thinking ? -12 : 0)), anchor: grid.anchor(baseX, 56))
    }

    private var cheek: some View {
        Circle()
            .fill(GardenStyle.petalPink.opacity(0.55))
            .sized(grid, 7, 7)
            .placedAt(grid, 24, 72)
    }

    private var mouth: some View {
        QuadStroke(from: CGPoint(x: 18, y: 76), control: CGPoint(x: 22, y: 80), to: CGPoint(x: 26, y: 76))
            .stroke(GardenStyle.ink, style: grid.stroke(2.2))
            .fullGrid(grid)
    }

    /// Teal shell with a rim, the sunGlow spiral dial clipped inside, and a static highlight.
    private var shell: some View {
        ZStack {
            Circle()
                .fill(GardenStyle.teal)
            Spiral(startRadius: grid.length(2.5), growth: grid.length(2.1), turns: 2.3)
                .stroke(GardenStyle.sunGlow.opacity(0.95), style: grid.stroke(4.5, minimum: 2))
                .rotationEffect(.degrees(progress * 360 + Double(turns) * 360))
                .animation(Motion.spring(reduceMotion), value: progress)
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6), value: turns)
                .clipShape(Circle())
            ArcShape(radius: grid.length(21), from: 200, to: 250)
                .stroke(Color.white.opacity(0.45), style: grid.stroke(4, minimum: 2))
            Circle()
                .strokeBorder(GardenStyle.tealDeep, lineWidth: grid.rim)
        }
        .sized(grid, 54, 54)
        .placedAt(grid, 62, 52)
    }
}

// MARK: - Butterfly (Flagra)

/// Symmetric, seen from above: the left wings are orange, the right wings teal, so the pairs
/// read as two parts of one whole. Wing pairs scale about the body like a shell opening.
private struct ButterflyDrawing: View {
    /// The wings mirror the orange and teal dot segments of Finn tallvennen. Set to false if a
    /// child tester links the wings to the counted dots: the wings turn petalPink and lilac.
    static let mirrorsEquation = true

    let grid: DesignGrid
    let t: Double
    let mood: CreatureMood
    let pose: HappyPose
    let reduceMotion: Bool

    private var thinking: Bool { mood == .thinking }
    private var happy: Bool { mood == .happy }
    /// Idle wing breath from fully open (t = 0) to 0.86.
    private var breath: CGFloat { 1 - 0.07 * CGFloat(1 - cos(2 * .pi * t / 2.4)) }
    /// Idle bob in grid units.
    private var bob: CGFloat { 3 * CGFloat(sin(2 * .pi * t / 2.4)) }

    var body: some View {
        ZStack {
            wingPair(left: true)
            wingPair(left: false)
            torso
            head
            antenna(left: true)
            antenna(left: false)
            face
        }
        .fullGrid(grid)
        .drawingGroup()
        .offset(y: grid.length(bob))
        .offset(y: grid.length(pose.lift))
        .rotationEffect(.degrees(pose.tilt))
        .offset(y: thinking ? -grid.length(3) : 0)
        .animation(Motion.quick(reduceMotion), value: mood)
    }

    private struct WingColours {
        let upper: Color
        let lower: Color
        let outline: Color
    }

    private func colours(left: Bool) -> WingColours {
        if Self.mirrorsEquation {
            return left
                ? WingColours(upper: GardenStyle.orange, lower: GardenStyle.orangeSoft, outline: GardenStyle.orangeDeep)
                : WingColours(upper: GardenStyle.teal, lower: GardenStyle.tealLight, outline: GardenStyle.tealDeep)
        }
        return left
            ? WingColours(upper: GardenStyle.petalPink, lower: GardenStyle.petalPink.opacity(0.75), outline: GardenStyle.petalRed)
            : WingColours(upper: GardenStyle.lilac, lower: GardenStyle.lilac.opacity(0.75), outline: GardenStyle.purple)
    }

    /// Upper and lower wing with an elongated highlight, scaled about the body (x = 50).
    private func wingPair(left: Bool) -> some View {
        let sign: Double = left ? -1 : 1
        let wing = colours(left: left)
        let highlightBright = happy && !left
        return ZStack {
            Ellipse()
                .fill(wing.lower)
                .overlay { Ellipse().strokeBorder(wing.outline, lineWidth: grid.line) }
                .sized(grid, 30, 34)
                .rotationEffect(.degrees(sign * 12))
                .placedAt(grid, left ? 34 : 66, 64)
            Ellipse()
                .fill(wing.upper)
                .overlay { Ellipse().strokeBorder(wing.outline, lineWidth: grid.line) }
                .sized(grid, 38, 46)
                .rotationEffect(.degrees(sign * 28))
                .placedAt(grid, left ? 31 : 69, 42)
            Ellipse()
                .fill(.white)
                .opacity(highlightBright ? 0.6 : 0.35)
                .animation(moodCrossfade, value: highlightBright)
                .sized(grid, 16, 24)
                .rotationEffect(.degrees(sign * 28))
                .placedAt(grid, left ? 27 : 73, 42)
        }
        .fullGrid(grid)
        .scaleEffect(x: breath, y: 1)
        .scaleEffect(x: pose.wing, y: 1)
        .scaleEffect(x: thinking ? 0.92 : 1, y: 1)
    }

    private var torso: some View {
        ZStack {
            Capsule()
                .fill(GardenStyle.soil)
                .overlay { Capsule().strokeBorder(GardenStyle.soilDeep, lineWidth: grid.line) }
                .sized(grid, 12, 52)
                .placedAt(grid, 50, 56)
            GridLine(from: CGPoint(x: 45, y: 60), to: CGPoint(x: 55, y: 60))
                .stroke(Color.white.opacity(0.25), lineWidth: max(1, grid.u))
                .fullGrid(grid)
            GridLine(from: CGPoint(x: 45, y: 72), to: CGPoint(x: 55, y: 72))
                .stroke(Color.white.opacity(0.25), lineWidth: max(1, grid.u))
                .fullGrid(grid)
        }
    }

    private var head: some View {
        Circle()
            .fill(GardenStyle.soil)
            .overlay { Circle().strokeBorder(GardenStyle.soilDeep, lineWidth: grid.line) }
            .sized(grid, 15, 15)
            .placedAt(grid, 50, 30)
    }

    /// A curved antenna with a round tip; the thinking pose leans it 15 degrees towards the task.
    private func antenna(left: Bool) -> some View {
        let root = CGPoint(x: left ? 46 : 54, y: 24)
        let control = CGPoint(x: left ? 38 : 62, y: 8)
        let tip = CGPoint(x: left ? 32 : 68, y: 10)
        return ZStack {
            QuadStroke(from: root, control: control, to: tip)
                .stroke(GardenStyle.soil, style: grid.stroke(2.2))
                .fullGrid(grid)
            Circle()
                .fill(GardenStyle.soil)
                .sized(grid, 4.5, 4.5)
                .placedAt(grid, tip.x, tip.y)
        }
        .fullGrid(grid)
        .rotationEffect(.degrees(thinking ? -15 : 0), anchor: grid.anchor(root.x, root.y))
    }

    private var face: some View {
        ZStack {
            eye(x: 46.5)
            eye(x: 53.5)
            QuadStroke(from: CGPoint(x: 47, y: 34), control: CGPoint(x: 50, y: 36.5), to: CGPoint(x: 53, y: 34))
                .stroke(GardenStyle.paper, style: grid.stroke(1.8))
                .fullGrid(grid)
        }
    }

    private func eye(x: CGFloat) -> some View {
        CreatureEyes.Eye(
            grid: grid,
            diameter: 3.5,
            ball: GardenStyle.paper,
            pupil: GardenStyle.ink,
            pupilDiameter: 1.6,
            arc: GardenStyle.paper,
            arcWidth: 1.6,
            arcRadius: 1.8,
            isHappy: happy,
            reduceMotion: reduceMotion
        )
        .placedAt(grid, x, 29)
    }
}

// MARK: - Bumblebee (Summa)

/// Flies left, towards the task: a soft yellow body with two dark bands, pale wings, no stinger,
/// no fuzz and no big cartoon eyes.
private struct BeeDrawing: View {
    let grid: DesignGrid
    let t: Double
    let mood: CreatureMood
    let pose: HappyPose
    let reduceMotion: Bool
    let reduceTransparency: Bool

    private var thinking: Bool { mood == .thinking }
    private var happy: Bool { mood == .happy }
    /// Idle hover in grid units.
    private var hover: CGFloat { 4 * CGFloat(sin(2 * .pi * t / 2.0)) }
    /// Idle wing shimmer (scale 1.0 to 0.85 over 1.6 s: far below 3 Hz, no opacity change).
    private var shimmer: CGFloat { 1 - 0.075 * CGFloat(1 - cos(2 * .pi * t / 1.6)) }
    /// Both wings grow from the top of the thorax.
    private let wingRoot = CGPoint(x: 47, y: 41)

    var body: some View {
        ZStack {
            wing(centre: CGPoint(x: 62, y: 35), width: 34, height: 18, angle: -34)
            wing(centre: CGPoint(x: 54, y: 38), width: 28, height: 15, angle: -22)
            torso
            head
            antenna(root: CGPoint(x: 20, y: 47), control: CGPoint(x: 12, y: 36), tip: CGPoint(x: 10, y: 30))
            antenna(root: CGPoint(x: 28, y: 46), control: CGPoint(x: 24, y: 34), tip: CGPoint(x: 22, y: 28))
            face
        }
        .fullGrid(grid)
        .drawingGroup()
        .offset(y: grid.length(hover))
        .offset(x: grid.length(pose.offset.width), y: grid.length(pose.offset.height))
        .rotationEffect(.degrees(pose.tilt))
        .offset(y: thinking ? -grid.length(4) : 0)
        .animation(Motion.quick(reduceMotion), value: mood)
    }

    /// A pale wing rotated about the shared root; the shimmer squashes it towards the body.
    /// The white inner stroke lifts it off white cards; the faint dark hairline keeps it
    /// visible on the sky band of a game screen.
    private func wing(centre: CGPoint, width: CGFloat, height: CGFloat, angle: Double) -> some View {
        Ellipse()
            .fill(reduceTransparency ? GardenStyle.skyTop : GardenStyle.skyTop.opacity(0.7))
            .overlay { Ellipse().strokeBorder(Color.white.opacity(0.6), lineWidth: max(1, grid.length(1.5))) }
            .overlay { Ellipse().stroke(GardenStyle.beeDark.opacity(0.3), lineWidth: max(0.8, grid.u)) }
            .sized(grid, width, height)
            .placedAt(grid, centre.x, centre.y)
            .fullGrid(grid)
            .scaleEffect(x: 1, y: shimmer, anchor: grid.anchor(wingRoot.x, wingRoot.y))
            .rotationEffect(.degrees(angle), anchor: grid.anchor(wingRoot.x, wingRoot.y))
    }

    /// Yellow body with two vertical bands clipped to the ellipse, then outlined.
    private var torso: some View {
        ZStack {
            Ellipse()
                .fill(GardenStyle.yellow)
            band(localX: 27)
            band(localX: 43)
        }
        .clipShape(Ellipse())
        .overlay { Ellipse().strokeBorder(GardenStyle.beeDark, lineWidth: grid.line) }
        .sized(grid, 58, 40)
        .placedAt(grid, 54, 60)
    }

    private func band(localX: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: grid.length(3))
            .fill(GardenStyle.beeDark)
            .sized(grid, 11, 44)
            .placedAt(grid, localX, 20)
    }

    private var head: some View {
        Circle()
            .fill(GardenStyle.yellow)
            .overlay { Circle().strokeBorder(GardenStyle.beeDark, lineWidth: grid.line) }
            .sized(grid, 24, 24)
            .placedAt(grid, 24, 58)
    }

    private func antenna(root: CGPoint, control: CGPoint, tip: CGPoint) -> some View {
        ZStack {
            QuadStroke(from: root, control: control, to: tip)
                .stroke(GardenStyle.beeDark, style: grid.stroke(2))
                .fullGrid(grid)
            Circle()
                .fill(GardenStyle.beeDark)
                .sized(grid, 4, 4)
                .placedAt(grid, tip.x, tip.y)
        }
        .fullGrid(grid)
        .rotationEffect(.degrees(thinking ? -10 : 0), anchor: grid.anchor(root.x, root.y))
    }

    private var face: some View {
        ZStack {
            eye(x: 19, y: 56)
            eye(x: 27, y: 55)
            Circle()
                .fill(GardenStyle.petalPink.opacity(0.55))
                .sized(grid, 6, 6)
                .placedAt(grid, 18, 63)
            QuadStroke(from: CGPoint(x: 20, y: 64), control: CGPoint(x: 23.5, y: 67), to: CGPoint(x: 27, y: 64))
                .stroke(GardenStyle.beeDark, style: grid.stroke(2))
                .fullGrid(grid)
        }
    }

    private func eye(x: CGFloat, y: CGFloat) -> some View {
        CreatureEyes.Eye(
            grid: grid,
            diameter: 4,
            pupil: GardenStyle.beeDark,
            pupilDiameter: 4,
            arc: GardenStyle.beeDark,
            arcWidth: 1.5,
            arcRadius: 2.2,
            isHappy: happy,
            reduceMotion: reduceMotion
        )
        .placedAt(grid, x, y)
    }
}

// MARK: - Hedgehog (Noste)

/// Faces left, brown and shoeless, with a leaf on its back. Idle: one blink and one sniff per
/// 4.5 s. Every progress change makes it sniff; the happy pose is a small hop, nothing more.
private struct HedgehogDrawing: View {
    let grid: DesignGrid
    let t: Double
    let mood: CreatureMood
    let sniffs: Int
    let pose: HappyPose
    let reduceMotion: Bool

    private var thinking: Bool { mood == .thinking }
    private var happy: Bool { mood == .happy }
    /// Position inside the 4.5 s idle cycle (0 at t = 0, outside every window: rest).
    private var cycle: Double { t.truncatingRemainder(dividingBy: 4.5) }

    /// Eye height during the blink window (1.2 s to 1.34 s of the cycle).
    private var blink: CGFloat {
        let p = (cycle - 1.2) / 0.14
        guard p >= 0, p <= 1 else { return 1 }
        return 1 - 0.9 * CGFloat(sin(.pi * p))
    }

    /// Nose scale during the idle sniff window (3.0 s to 3.3 s of the cycle).
    private var idleSniff: CGFloat {
        let p = (cycle - 3.0) / 0.3
        guard p >= 0, p <= 1 else { return 1 }
        return 1 + 0.15 * CGFloat(sin(.pi * p))
    }

    var body: some View {
        ZStack {
            shadow
            spines(peak: 36, valley: 27, fill: GardenStyle.soil, outline: grid.stroke(3, minimum: 1.5))
            spines(peak: 29, valley: 21, fill: GardenStyle.soilLight.opacity(0.9), outline: grid.stroke(1.2))
            belly
            snoutGroup
            eye
            cheek
            foot(x: 36)
            foot(x: 62)
            leaf
        }
        .fullGrid(grid)
        .drawingGroup()
        .scaleEffect(pose.scale, anchor: .bottom)
        .offset(y: grid.length(pose.lift))
        .animation(Motion.quick(reduceMotion), value: mood)
    }

    private var shadow: some View {
        Ellipse()
            .fill(GardenStyle.ink.opacity(0.08))
            .sized(grid, 70, 9)
            .placedAt(grid, 52, 90)
    }

    private func spines(peak: CGFloat, valley: CGFloat, fill: Color, outline: StrokeStyle) -> some View {
        let dome = SpineDome(centre: CGPoint(x: 52, y: 74), peak: peak, valley: valley)
        return ZStack {
            dome.fill(fill)
            dome.stroke(GardenStyle.soilDeep, style: outline)
        }
        .fullGrid(grid)
    }

    private var belly: some View {
        Ellipse()
            .fill(GardenStyle.sand)
            .overlay { Ellipse().strokeBorder(GardenStyle.sandDeep, lineWidth: grid.line) }
            .sized(grid, 64, 36)
            .placedAt(grid, 50, 72)
    }

    /// Snout, nose and mouth; the thinking pose lifts the nose (a clockwise turn on screen
    /// raises the left-pointing tip).
    private var snoutGroup: some View {
        ZStack {
            SnoutShape()
                .fill(GardenStyle.sand)
                .fullGrid(grid)
            SnoutShape()
                .stroke(GardenStyle.sandDeep, style: grid.stroke(1.7, minimum: 1.2))
                .fullGrid(grid)
            nose
            QuadStroke(from: CGPoint(x: 14, y: 81), control: CGPoint(x: 18, y: 84), to: CGPoint(x: 22, y: 81))
                .stroke(GardenStyle.ink, style: grid.stroke(1.8))
                .fullGrid(grid)
        }
        .fullGrid(grid)
        .rotationEffect(.degrees(thinking ? 8 : 0), anchor: grid.anchor(34, 75))
    }

    /// The nose sniffs on every progress change (PhaseAnimator 1.0 to 1.15 and back, 0.25 s).
    @ViewBuilder
    private var nose: some View {
        if reduceMotion {
            noseDot(scale: 1)
        } else {
            PhaseAnimator([1.0, 1.15], trigger: sniffs) { scale in
                noseDot(scale: scale)
            } animation: { _ in
                .easeOut(duration: 0.12)
            }
        }
    }

    private func noseDot(scale: Double) -> some View {
        Circle()
            .fill(GardenStyle.ink)
            .sized(grid, 8, 8)
            .scaleEffect(idleSniff)
            .scaleEffect(CGFloat(scale))
            .placedAt(grid, 9, 76)
    }

    private var eye: some View {
        CreatureEyes.Eye(
            grid: grid,
            diameter: 4.2,
            pupil: GardenStyle.ink,
            pupilDiameter: 4.2,
            glint: true,
            arc: GardenStyle.ink,
            arcWidth: 1.5,
            arcRadius: 2.4,
            isHappy: happy,
            reduceMotion: reduceMotion
        )
        .scaleEffect(x: 1, y: blink)
        .scaleEffect(thinking ? 1.1 : 1)
        .placedAt(grid, 26, 70)
    }

    private var cheek: some View {
        Circle()
            .fill(GardenStyle.petalPink.opacity(0.5))
            .sized(grid, 6, 6)
            .placedAt(grid, 26, 78)
    }

    private func foot(x: CGFloat) -> some View {
        Capsule()
            .fill(GardenStyle.soil)
            .overlay { Capsule().strokeBorder(GardenStyle.soilDeep, lineWidth: grid.line) }
            .sized(grid, 14, 8)
            .placedAt(grid, x, 88)
    }

    /// A leaf resting on the spines; it tilts further during the hop.
    private var leaf: some View {
        ZStack {
            Ellipse()
                .fill(GardenStyle.leaf)
                .overlay { Ellipse().strokeBorder(GardenStyle.leafDeep, lineWidth: max(1, grid.u)) }
            Rectangle()
                .fill(GardenStyle.hillMid)
                .frame(height: max(1, grid.length(1.5)))
                .padding(.horizontal, grid.length(2))
        }
        .sized(grid, 24, 12)
        .rotationEffect(.degrees(-30 + pose.leafTilt))
        .placedAt(grid, 58, 42)
    }
}

// MARK: - Petal burst

/// Eight capsule petals that fly out from the guide's centre, spin, shrink and fade in 0.7 s.
/// They stay inside the creature's own frame, so the burst never reaches a panel or a dot frame.
/// Never inserted under Reduce Motion (the caller checks) and invisible before the first trigger.
private struct PetalBurst: View {
    let trigger: Int
    let size: CGFloat
    let tint: Color

    private var colours: [Color] {
        [GardenStyle.petalPink, GardenStyle.yellow, tint.opacity(0.7), .white, GardenStyle.sunGlow, GardenStyle.lilac]
    }

    var body: some View {
        KeyframeAnimator(initialValue: 0.0, trigger: trigger) { progress in
            petals(progress: progress)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(1.0, duration: 0.7)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func petals(progress: Double) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                petal(index: index, progress: progress)
            }
        }
        .opacity(trigger == 0 ? 0 : 1 - progress * progress)
    }

    private func petal(index: Int, progress: Double) -> some View {
        let angle = Double(index) * 45 + 12 * Double((index % 3) - 1)
        let radians = angle * .pi / 180
        // Ease out along the flight so petals leave quickly and drift at the end.
        let travel = 1 - (1 - progress) * (1 - progress)
        let distance = size * CGFloat(0.18 + 0.32 * travel)
        return Capsule()
            .fill(colours[index % colours.count])
            .frame(width: size * 5 / 88, height: size * 11 / 88)
            .rotationEffect(.degrees(angle - 90 + 160 * progress))
            .scaleEffect(CGFloat(1 - 0.4 * progress))
            .offset(x: distance * CGFloat(cos(radians)), y: distance * CGFloat(sin(radians)))
    }
}
