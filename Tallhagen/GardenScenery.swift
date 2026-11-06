import SwiftUI

// Garden scenery: the palette tokens, the tuning constants, the screen backdrop (sky, sun,
// clouds, hills and a flower field), a single flower, and the meadow strip that carries the
// sound button and the home progress bed. Everything in this file is decoration drawn from
// SwiftUI shapes: hidden from VoiceOver, never hit-testable, and perfectly still under
// Reduce Motion. Nothing here may look like a countable quantity next to a dot frame:
// petals, leaves and clouds are ellipses, capsules and arcs; flower centres are flat yellow
// discs of at most 5.5 pt; and no gradient-filled circle with a white rim exists between
// 7 and 24 pt, the BeadGroup dot range (the sun is 112 pt or larger).

// MARK: - Palette

/// Garden colours added to the base palette in Theme.swift. This file is the sole owner of
/// these tokens; GardenCreatures.swift uses the names and defines none. Contrast notes use the
/// WCAG formula with `ink` and `muted` from Theme.swift as the text colours: ink reads on every
/// scenery colour (6.03:1 on hillNear at the lowest); muted is safe only on white, paper, the
/// cloud veil, skyPale, skyGlow, meadowMist and sunGlow; teal, purple and blue text only on
/// white, paper or the veil. Child-facing text therefore always sits on white, paper, the soil
/// sign or a cloud veil, never bare on a hill, a plant, sand or the sun.
extension GardenStyle {
    /// Top of the home and chooser sky and of the game sky band (ink 9.79:1, muted 4.74:1;
    /// only ink and the hidden wordmark ever sit bare on it).
    static let skyTop = Color(red: 0.78, green: 0.90, blue: 0.97)
    /// Mid sky; the game band from 35 % down (muted 5.46:1, so the game subtitle is safe).
    static let skyPale = Color(red: 0.90, green: 0.95, blue: 0.98)
    /// Warm cream horizon stop in the mesh and linear sky (muted 5.60:1).
    static let skyGlow = Color(red: 0.99, green: 0.95, blue: 0.87)
    /// Bottom sky stop where the sky meets the far hill (muted 5.37:1).
    static let meadowMist = Color(red: 0.90, green: 0.95, blue: 0.88)

    /// Farthest hill layer on home and chooser (ink 9.39:1).
    static let hillFar = Color(red: 0.80, green: 0.89, blue: 0.78)
    /// Middle hill; the back bump of `GardenMeadow` (ink 7.74:1; never under muted or tinted text).
    static let hillMid = Color(red: 0.67, green: 0.83, blue: 0.66)
    /// Nearest hill and the `GardenMeadow` grass under the sound button (ink 6.03:1, the floor
    /// for bare ink; white on it is only 2.13:1, so the sound capsule needs a ground ellipse).
    static let hillNear = Color(red: 0.53, green: 0.75, blue: 0.54)
    /// Stems, leaves, grass tufts and the ground ellipse under the sound capsule. Never under text.
    static let leaf = Color(red: 0.30, green: 0.58, blue: 0.40)
    /// Leaf veins and the 1 pt outline on stems in the footer and bed (5.94:1 on white).
    static let leafDeep = Color(red: 0.18, green: 0.44, blue: 0.28)

    /// Home header signboard fill (white display text on it 5.56:1); hedgehog spines and feet,
    /// butterfly body and antennae; the soil strip of the progress bed.
    static let soil = Color(red: 0.52, green: 0.38, blue: 0.26)
    /// Lighter soil: the hedgehog's second spine layer, the chooser card posts, the bed surface.
    static let soilLight = Color(red: 0.71, green: 0.57, blue: 0.45)
    /// Outline of the signboard and of soil-coloured creature parts (8.77:1 on white).
    static let soilDeep = Color(red: 0.38, green: 0.27, blue: 0.18)
    /// Snail body and head, hedgehog face and belly (ink 9.31:1 for their features).
    static let sand = Color(red: 0.95, green: 0.85, blue: 0.66)
    /// 1.5 pt outline on every sand-coloured part (4.41:1 on white, 3.36:1 on skyTop).
    static let sandDeep = Color(red: 0.60, green: 0.44, blue: 0.27)

    /// Sun halo, the warm mesh point beside the sun, the snail's spiral ribbon, one daisy
    /// petal colour. The game wordmark lands on it (muted 5.34:1), never on the disc.
    static let sunGlow = Color(red: 1.00, green: 0.93, blue: 0.72)
    /// Daisy petals, bed flowers, creature cheeks at 0.5, burst petals.
    static let petalPink = Color(red: 0.96, green: 0.68, blue: 0.76)
    /// Tulip heads and one bed petal colour (never under text, ink 3.84:1).
    static let petalRed = Color(red: 0.88, green: 0.40, blue: 0.42)
    /// Second tulip colour, bed petal colour, burst petal; a light relative of purple that is
    /// never used at dot sizes as a filled circle.
    static let lilac = Color(red: 0.74, green: 0.62, blue: 0.90)

    /// Butterfly right lower wings (also used by Tools/MakeIcon.swift, so home and icon rhyme).
    static let tealLight = Color(red: 0.56, green: 0.78, blue: 0.76)
    /// Rim of the snail shell and outline of the butterfly's teal wings (7.92:1 on white).
    static let tealDeep = Color(red: 0.00, green: 0.36, blue: 0.33)
    /// Butterfly left lower wings, the sun's rim, third tulip colour (from MakeIcon.swift).
    static let orangeSoft = Color(red: 0.93, green: 0.52, blue: 0.34)
    /// Outline of the butterfly's orange wings (6.33:1 on white, 4.83:1 on skyTop).
    static let orangeDeep = Color(red: 0.62, green: 0.27, blue: 0.10)
    /// Bee bands, antennae, eyes, mouth and body outline (13.45:1 on white).
    static let beeDark = Color(red: 0.20, green: 0.18, blue: 0.16)

    /// The cloud veil behind child-facing text on the home and chooser: white at 0.88, or
    /// opaque white under Reduce Transparency. Muted text on it measures 5.44:1 or better over
    /// any scenery colour; teal 4.56:1 and purple 4.75:1 or better; blue text never sits on it.
    static func cloudVeil(opaque: Bool) -> Color {
        opaque ? Color.white : Color.white.opacity(0.88)
    }
}

// MARK: - Tuning

/// Performance levers for the garden. Lower the frame rate or the plant counts first if an
/// old iPad drops frames; the bloom cap keeps the progress bed bounded.
enum GardenTuning {
    /// Minimum interval of the scenery and creature clocks: 20 frames per second.
    static let frameInterval: Double = 1.0 / 20
    /// Plants in the pinned flower field at regular widths.
    static let flowerCountRegular = 9
    /// Plants in the pinned flower field at compact widths (Split View, Slide Over).
    static let flowerCountCompact = 3
    /// Most flowers the home progress bed ever shows: one per solved task, and only what fits.
    static let bloomCap = 40
    /// Height of the grass footer that carries the sound button, before the home-indicator area.
    static let footerHeight: CGFloat = 92
}

// MARK: - Backdrop

/// The full-screen garden behind a screen. Place it first in the ZStack where
/// `GardenStyle.paper.ignoresSafeArea()` used to be.
///
/// `.home` and `.chooser` draw a morning sky, a faceless sun, two clouds, three hills and a
/// swaying flower field; `.game(tint)` draws paper with a 260 pt sky band, a faint tint haze
/// and the quarter sun in the top trailing corner, so every panel sits on paper or white.
/// One `TimelineView` clock (20 fps, paused when the scene is inactive or the screen is
/// covered) feeds every moving layer; each pose is a sine of the clock with its rest pose at
/// t = 0, so under Reduce Motion, where the clock is never created, the garden is a still image.
/// Increase Contrast replaces the sky with flat paper; Reduce Transparency makes clouds opaque.
struct GardenBackground: View {
    enum Style {
        case home
        case chooser
        case game(Color)
    }

    private let style: Style

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// False while a pushed game covers the home screen, so its clock does not run unseen.
    @State private var isOnScreen = true

    init(style: Style) {
        self.style = style
    }

    private var isPaused: Bool { scenePhase != .active || !isOnScreen }
    private var increasedContrast: Bool { colorSchemeContrast == .increased }
    private var isCompact: Bool { horizontalSizeClass == .compact }

    private var skyVariant: SkyVariant {
        if case .chooser = style { return .chooser }
        return .home
    }

    var body: some View {
        GeometryReader { proxy in
            backdrop(size: proxy.size)
        }
        .ignoresSafeArea()
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func backdrop(size: CGSize) -> some View {
        switch style {
        case .game(let tint):
            GameBackdrop(tint: tint, size: size, increasedContrast: increasedContrast)
        case .home, .chooser:
            if reduceMotion {
                scene(size: size, t: 0)
            } else {
                TimelineView(.animation(minimumInterval: GardenTuning.frameInterval, paused: isPaused)) { context in
                    scene(size: size, t: isPaused ? 0 : context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
    }

    /// Home and chooser layers, back to front: sky, sun, clouds, hills, flower field.
    @ViewBuilder
    private func scene(size: CGSize, t: Double) -> some View {
        let layout = SceneLayout(variant: skyVariant, size: size, compact: isCompact)
        ZStack(alignment: .topLeading) {
            SkyLayer(
                variant: skyVariant,
                size: size,
                sunUnitPoint: layout.sunUnitPoint,
                increasedContrast: increasedContrast,
                t: t
            )
            SunView(
                center: layout.sunCenter,
                radius: layout.sunRadius,
                haloRadius: layout.haloRadius,
                haloOpacity: layout.haloOpacity,
                breath: layout.isCornerSun ? 1 : 1 + 0.04 * sin(2 * .pi * t / 6)
            )
            CloudView(center: layout.firstCloud, drift: 10 * sin(t / 30), opaque: reduceTransparency)
            if let secondCloud = layout.secondCloud {
                CloudView(center: secondCloud, drift: -10 * sin(t / 30), opaque: reduceTransparency)
            }
            HillLayer(size: size)
                .equatable()
            FlowerField(plants: layout.plants, t: t)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

/// Which of the two scenic skies is drawn; games never use the mesh.
private enum SkyVariant {
    case home
    case chooser
}

/// Positions of the sun, clouds and plants for one screen size. Pure geometry, no state.
private struct SceneLayout {
    let variant: SkyVariant
    let size: CGSize
    let compact: Bool

    private static let plantSizes: [CGFloat] = [36, 28, 44, 32, 40, 30, 44, 34, 38]
    private static let homeAnchors: [CGFloat] = [0.05, 0.12, 0.20, 0.31, 0.44, 0.58, 0.70, 0.83, 0.93]
    private static let chooserAnchors: [CGFloat] = [0.04, 0.10, 0.17, 0.50, 0.83, 0.90, 0.96]
    private static let compactIndices = [1, 4, 7]
    private static let daisyPetals: [Color] = [GardenStyle.petalPink, Color.white.opacity(0.95), GardenStyle.sunGlow]
    private static let tulipPetals: [Color] = [GardenStyle.petalRed, GardenStyle.lilac, GardenStyle.orangeSoft]

    /// Compact widths show the corner quarter sun of the game screens.
    var isCornerSun: Bool { compact }

    var sunCenter: CGPoint {
        if compact {
            return CGPoint(x: size.width - 26, y: -28)
        }
        switch variant {
        case .home:
            // Behind the rotated "3 + 4 = 7" hero card, 57 pt below the header row.
            let columnRight = size.width / 2 + min(size.width, 1030) / 2 - 26
            return CGPoint(x: columnRight - 150, y: 232)
        case .chooser:
            // The low morning sun, left of the centred card row, partly behind the far hill.
            return CGPoint(x: 110, y: 0.52 * size.height)
        }
    }

    var sunRadius: CGFloat {
        if compact { return 56 }
        return variant == .home ? 80 : 85
    }

    var haloRadius: CGFloat {
        if compact { return 150 }
        return variant == .home ? 176 : 187
    }

    var haloOpacity: Double { compact ? 0.7 : 0.6 }

    var sunUnitPoint: UnitPoint {
        UnitPoint(x: sunCenter.x / max(size.width, 1), y: sunCenter.y / max(size.height, 1))
    }

    var firstCloud: CGPoint {
        CGPoint(x: 0.15 * size.width, y: 0.14 * size.height)
    }

    var secondCloud: CGPoint? {
        compact ? nil : CGPoint(x: 0.55 * size.width, y: 0.07 * size.height)
    }

    /// Plants rooted 6 pt below the middle hill's crest. Kinds cycle daisy, tulip, tuft;
    /// colours cycle per kind; positions are deterministic (no random numbers), so the
    /// garden looks the same on every launch.
    var plants: [GardenPlant] {
        let anchors = Array((variant == .home ? Self.homeAnchors : Self.chooserAnchors).prefix(GardenTuning.flowerCountRegular))
        let indices: [Int]
        if compact {
            indices = Self.compactIndices.filter { $0 < anchors.count }.prefix(GardenTuning.flowerCountCompact).map { $0 }
        } else {
            indices = Array(anchors.indices)
        }
        return indices.map { index in
            let fraction = anchors[index]
            let jitter = CGFloat((index * 7) % 5 - 2) * 3
            let base = CGPoint(
                x: fraction * size.width + jitter,
                y: HillShape.mid.crestY(atFraction: fraction, height: size.height) + 6
            )
            let kind: GardenPlant.Kind
            switch index % 3 {
            case 0: kind = .daisy(Self.daisyPetals[(index / 3) % Self.daisyPetals.count])
            case 1: kind = .tulip(Self.tulipPetals[(index / 3) % Self.tulipPetals.count])
            default: kind = .tuft
            }
            return GardenPlant(index: index, base: base, size: Self.plantSizes[index % Self.plantSizes.count], kind: kind)
        }
    }
}

/// One plant of the pinned flower field.
private struct GardenPlant {
    enum Kind {
        case daisy(Color)
        case tulip(Color)
        case tuft
    }

    let index: Int
    let base: CGPoint
    let size: CGFloat
    let kind: Kind

    /// 3 degrees (tufts 2) of sway about the base; periods above 5 s, rest at t = 0.
    func sway(at t: Double) -> Angle {
        let amplitude: Double
        if case .tuft = kind { amplitude = 2 } else { amplitude = 3 }
        return .degrees(amplitude * sin(1.1 * t + 0.9 * Double(index)))
    }
}

/// Flat paper under Increase Contrast, a breathing mesh on iOS 18, a static linear sky with a
/// radial sun glow on iOS 17.
private struct SkyLayer: View {
    let variant: SkyVariant
    let size: CGSize
    let sunUnitPoint: UnitPoint
    let increasedContrast: Bool
    let t: Double

    var body: some View {
        if increasedContrast {
            GardenStyle.paper
        } else if #available(iOS 18, *) {
            MeshSky(variant: variant, t: t)
        } else {
            LinearSky(size: size, sunUnitPoint: sunUnitPoint)
        }
    }
}

/// iOS 18 sky: a 3 x 3 mesh whose centre point drifts a few percent over about a minute.
/// At t = 0 it is exactly the rest mesh. Only pale colours, and no muted or tinted text ever
/// sits bare on it, so bicubic overshoot cannot create a contrast failure.
@available(iOS 18, *)
private struct MeshSky: View {
    let variant: SkyVariant
    let t: Double

    private var colors: [Color] {
        switch variant {
        case .home:
            return [
                GardenStyle.skyTop, GardenStyle.skyTop, GardenStyle.skyPale,
                GardenStyle.skyPale, GardenStyle.skyGlow, GardenStyle.sunGlow,
                GardenStyle.meadowMist, GardenStyle.skyGlow, GardenStyle.skyGlow,
            ]
        case .chooser:
            return [
                GardenStyle.skyTop, GardenStyle.skyTop, GardenStyle.skyPale,
                GardenStyle.sunGlow, GardenStyle.skyGlow, GardenStyle.skyPale,
                GardenStyle.skyGlow, GardenStyle.skyGlow, GardenStyle.meadowMist,
            ]
        }
    }

    var body: some View {
        let dx = Float(0.04 * sin(t / 9))
        let dy = Float(0.03 * sin(t / 7))
        let points: [SIMD2<Float>] = [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5], [0.5 + dx, 0.5 + dy], [1, 0.5],
            [0, 1], [0.5, 1], [1, 1],
        ]
        MeshGradient(width: 3, height: 3, points: points, colors: colors)
    }
}

/// iOS 17 sky: a vertical gradient plus a warm radial glow at the sun. Static.
private struct LinearSky: View {
    let size: CGSize
    let sunUnitPoint: UnitPoint

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: GardenStyle.skyTop, location: 0),
                    .init(color: GardenStyle.skyPale, location: 0.42),
                    .init(color: GardenStyle.skyGlow, location: 0.78),
                    .init(color: GardenStyle.meadowMist, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [GardenStyle.sunGlow.opacity(0.75), GardenStyle.sunGlow.opacity(0)],
                center: sunUnitPoint,
                startRadius: 0,
                endRadius: 0.55 * size.width
            )
        }
    }
}

/// A faceless, ray-less sun: a warm disc with a thin white rim inside a soft halo.
/// `breath` scales the halo only (1 + 0.04 sin(2 pi t / 6) on home and chooser, 1 in games).
private struct SunView: View {
    let center: CGPoint
    let radius: CGFloat
    let haloRadius: CGFloat
    let haloOpacity: Double
    let breath: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [GardenStyle.sunGlow.opacity(haloOpacity), GardenStyle.sunGlow.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: haloRadius
                    )
                )
                .frame(width: haloRadius * 2, height: haloRadius * 2)
                .scaleEffect(breath)
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: GardenStyle.sunGlow, location: 0),
                            .init(color: GardenStyle.yellow, location: 0.7),
                            .init(color: GardenStyle.orangeSoft, location: 1),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 3)
                }
                .frame(width: radius * 2, height: radius * 2)
        }
        .position(center)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// A soft cloud: four white circles over a rounded base, flattened before the 0.85 opacity is
/// applied so overlaps never show through. Opaque under Reduce Transparency.
private struct CloudView: View {
    let center: CGPoint
    let drift: CGFloat
    let opaque: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 142, height: 32)
                .offset(x: 4, y: 40)
            Circle()
                .frame(width: 44, height: 44)
                .offset(x: 8, y: 26)
            Circle()
                .frame(width: 68, height: 68)
                .offset(x: 28, y: 0)
            Circle()
                .frame(width: 56, height: 56)
                .offset(x: 70, y: 14)
            Circle()
                .frame(width: 40, height: 40)
                .offset(x: 108, y: 32)
        }
        .foregroundStyle(Color.white)
        .frame(width: 150, height: 72, alignment: .topLeading)
        .compositingGroup()
        .opacity(opaque ? 1 : 0.85)
        .position(x: center.x + drift, y: center.y)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// One rolling hill: a cubic crest from the leading to the trailing edge, closed along the
/// bottom. All control points are fractions of the screen so the three layers stack the same
/// way in every orientation.
private struct HillShape: Shape {
    let startY: CGFloat
    let endY: CGFloat
    let control1: CGPoint
    let control2: CGPoint

    static let far = HillShape(startY: 0.62, endY: 0.60, control1: CGPoint(x: 0.30, y: 0.48), control2: CGPoint(x: 0.70, y: 0.70))
    static let mid = HillShape(startY: 0.74, endY: 0.72, control1: CGPoint(x: 0.25, y: 0.62), control2: CGPoint(x: 0.75, y: 0.84))
    static let near = HillShape(startY: 0.86, endY: 0.84, control1: CGPoint(x: 0.35, y: 0.76), control2: CGPoint(x: 0.70, y: 0.92))

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + startY * h))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + endY * h),
            control1: CGPoint(x: rect.minX + control1.x * w, y: rect.minY + control1.y * h),
            control2: CGPoint(x: rect.minX + control2.x * w, y: rect.minY + control2.y * h)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    /// The crest's y at Bézier parameter `fraction` (used as the x fraction; close enough for
    /// planting), in points for a screen `height` tall.
    func crestY(atFraction fraction: CGFloat, height: CGFloat) -> CGFloat {
        let s = min(max(fraction, 0), 1)
        let u = 1 - s
        let y = u * u * u * startY
            + 3 * u * u * s * control1.y
            + 3 * u * s * s * control2.y
            + s * s * s * endY
        return y * height
    }
}

/// The three static hills. Equatable so the scenery clock never re-evaluates it.
private struct HillLayer: View, Equatable {
    let size: CGSize

    var body: some View {
        ZStack {
            HillShape.far.fill(GardenStyle.hillFar)
            HillShape.mid.fill(GardenStyle.hillMid)
            HillShape.near.fill(GardenStyle.hillNear)
        }
        .frame(width: size.width, height: size.height)
        .drawingGroup()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Every plant of the pinned garden in one Canvas, redrawn per clock tick (a handful of
/// small paths; cheap). Each plant sways about its own base.
private struct FlowerField: View {
    let plants: [GardenPlant]
    let t: Double

    var body: some View {
        Canvas { context, _ in
            for plant in plants {
                let sway = plant.sway(at: t)
                switch plant.kind {
                case .daisy(let petal):
                    GardenFlower.drawDaisy(in: &context, base: plant.base, size: plant.size, petal: petal, sway: sway)
                case .tulip(let petal):
                    GardenFlower.drawTulip(in: &context, base: plant.base, size: plant.size, petal: petal, sway: sway)
                case .tuft:
                    GardenFlower.drawTuft(in: &context, base: plant.base, size: plant.size, sway: sway)
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Game screens: paper, a 260 pt sky band, a 7 % tint haze at the horizon and the quarter sun
/// in the top trailing corner. No hills, clouds or flowers, so every panel sits on paper or
/// white and nothing decorative comes near a dot frame. Static; identical in compact widths.
/// Under Increase Contrast the band and haze are dropped and the sun stays.
private struct GameBackdrop: View {
    let tint: Color
    let size: CGSize
    let increasedContrast: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            GardenStyle.paper
            if !increasedContrast {
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: GardenStyle.skyTop, location: 0),
                                .init(color: GardenStyle.skyPale, location: 0.35),
                                .init(color: GardenStyle.paper, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 260)
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: tint.opacity(0), location: 0),
                                .init(color: tint.opacity(0.07), location: 0.5),
                                .init(color: tint.opacity(0), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 140)
                    .offset(y: 150)
            }
            SunView(
                center: CGPoint(x: size.width - 26, y: -28),
                radius: 56,
                haloRadius: 150,
                haloOpacity: 0.7,
                breath: 1
            )
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

// MARK: - Flower

/// One daisy in a `size` x `size` frame, rooted at the bottom centre: the sprout at a
/// creature's feet and the side flowers of the footer. The same drawing code feeds the
/// pinned flower field and the progress bed through the static `draw...` functions.
///
/// Petals are ellipses, the centre is a flat yellow disc of 3.3 to 5.5 pt, the stem has a
/// 1 pt `leafDeep` outline: nothing a child could mistake for a counted dot.
struct GardenFlower: View {
    let tint: Color
    let size: CGFloat

    init(tint: Color, size: CGFloat) {
        self.tint = tint
        self.size = size
    }

    var body: some View {
        Canvas { context, canvasSize in
            GardenFlower.drawDaisy(
                in: &context,
                base: CGPoint(x: canvasSize.width / 2, y: canvasSize.height - 1.5),
                size: size,
                petal: tint,
                sway: .zero
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    // Drawing is done into copies of the context, so the base translation and the sway
    // rotation never leak into the caller's state.

    /// Draws a daisy whose base (the bottom of the stem) is at `base`, about `size` pt tall and
    /// at most `size` pt wide, rotated by `sway` about the base.
    static func drawDaisy(in context: inout GraphicsContext, base: CGPoint, size: CGFloat, petal: Color, sway: Angle) {
        var plant = context
        plant.translateBy(x: base.x, y: base.y)
        plant.rotate(by: sway)

        let head = CGPoint(x: 0, y: -0.60 * size)
        drawStem(in: &plant, to: CGPoint(x: 0, y: -0.56 * size), size: size)
        drawLeaf(
            in: &plant,
            center: CGPoint(x: 0.13 * size, y: -0.30 * size),
            length: 0.30 * size,
            width: 0.13 * size,
            rotation: .degrees(-32)
        )

        let petalLength = 0.28 * size
        let petalWidth = 0.13 * size
        let ring = petalLength / 2 + 0.02 * size
        for index in 0..<8 {
            let angle = Angle.degrees(Double(index) * 45)
            let center = CGPoint(
                x: head.x + ring * CGFloat(cos(angle.radians)),
                y: head.y + ring * CGFloat(sin(angle.radians))
            )
            let shape = ellipse(center: center, length: petalLength, width: petalWidth, rotation: angle)
            plant.fill(shape, with: .color(petal))
            plant.stroke(shape, with: .color(GardenStyle.ink.opacity(0.14)), lineWidth: 1)
        }

        // Flat centre, never larger than 5.5 pt.
        let centre = min(5.5, max(3.3, 0.125 * size))
        plant.fill(
            Path(ellipseIn: CGRect(x: head.x - centre / 2, y: head.y - centre / 2, width: centre, height: centre)),
            with: .color(GardenStyle.yellow)
        )
    }

    /// Draws a tulip (a cup with three soft tips on a stem with two leaves) rooted at `base`.
    static func drawTulip(in context: inout GraphicsContext, base: CGPoint, size: CGFloat, petal: Color, sway: Angle) {
        var plant = context
        plant.translateBy(x: base.x, y: base.y)
        plant.rotate(by: sway)

        drawStem(in: &plant, to: CGPoint(x: 0, y: -0.60 * size), size: size)
        drawLeaf(
            in: &plant,
            center: CGPoint(x: -0.11 * size, y: -0.26 * size),
            length: 0.36 * size,
            width: 0.10 * size,
            rotation: .degrees(68)
        )
        drawLeaf(
            in: &plant,
            center: CGPoint(x: 0.10 * size, y: -0.20 * size),
            length: 0.30 * size,
            width: 0.09 * size,
            rotation: .degrees(-62)
        )

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * size, y: y * size)
        }
        var cup = Path()
        cup.move(to: point(-0.17, -0.62))
        cup.addQuadCurve(to: point(-0.19, -0.86), control: point(-0.21, -0.74))
        cup.addQuadCurve(to: point(-0.065, -0.79), control: point(-0.13, -0.79))
        cup.addQuadCurve(to: point(0, -0.89), control: point(-0.03, -0.85))
        cup.addQuadCurve(to: point(0.065, -0.79), control: point(0.03, -0.85))
        cup.addQuadCurve(to: point(0.19, -0.86), control: point(0.13, -0.79))
        cup.addQuadCurve(to: point(0.17, -0.62), control: point(0.21, -0.74))
        cup.addQuadCurve(to: point(-0.17, -0.62), control: point(0, -0.50))
        cup.closeSubpath()
        plant.fill(cup, with: .color(petal))
        plant.stroke(cup, with: .color(GardenStyle.ink.opacity(0.14)), lineWidth: 1)
    }

    /// Draws a tuft of five grass blades fanning out from `base`, about `size` pt tall.
    static func drawTuft(in context: inout GraphicsContext, base: CGPoint, size: CGFloat, sway: Angle) {
        var plant = context
        plant.translateBy(x: base.x, y: base.y)
        plant.rotate(by: sway)

        let lineWidth = max(1.6, 0.07 * size)
        for index in 0..<5 {
            let k = CGFloat(index - 2)
            let tip = CGPoint(x: k * 0.20 * size, y: -size * (0.90 - 0.14 * abs(k)))
            var blade = Path()
            blade.move(to: .zero)
            blade.addQuadCurve(to: tip, control: CGPoint(x: k * 0.05 * size, y: -0.52 * size))
            let color = index % 2 == 0 ? GardenStyle.leaf : GardenStyle.leafDeep
            plant.stroke(blade, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }

    /// A gently curved stem from the origin up to `top`, leaf green with a 1 pt leafDeep outline.
    private static func drawStem(in context: inout GraphicsContext, to top: CGPoint, size: CGFloat) {
        var stem = Path()
        stem.move(to: .zero)
        stem.addQuadCurve(to: top, control: CGPoint(x: -0.05 * size, y: top.y * 0.5))
        let width = max(1.6, 0.065 * size)
        context.stroke(stem, with: .color(GardenStyle.leafDeep), style: StrokeStyle(lineWidth: width + 2, lineCap: .round))
        context.stroke(stem, with: .color(GardenStyle.leaf), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// An elliptical leaf with a midrib. `rotation` turns the long axis (positive is
    /// clockwise on screen, so +68 degrees points up-left and -62 degrees up-right).
    private static func drawLeaf(in context: inout GraphicsContext, center: CGPoint, length: CGFloat, width: CGFloat, rotation: Angle) {
        let shape = ellipse(center: center, length: length, width: width, rotation: rotation)
        context.fill(shape, with: .color(GardenStyle.leaf))
        context.stroke(shape, with: .color(GardenStyle.leafDeep), lineWidth: 1)

        let dx = CGFloat(cos(rotation.radians)) * length * 0.42
        let dy = CGFloat(sin(rotation.radians)) * length * 0.42
        var rib = Path()
        rib.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
        rib.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
        context.stroke(rib, with: .color(GardenStyle.leafDeep.opacity(0.7)), lineWidth: 1)
    }

    /// An ellipse of `length` along its (rotated) long axis and `width` across, centred on `center`.
    private static func ellipse(center: CGPoint, length: CGFloat, width: CGFloat, rotation: Angle) -> Path {
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: CGFloat(rotation.radians))
        return Path(ellipseIn: CGRect(x: -length / 2, y: -width / 2, width: length, height: width))
            .applying(transform)
    }
}

// MARK: - Meadow

/// A strip of grass: a middle-hill bump at the back, near grass with a wavy edge in front and
/// a few tufts. With `bloomCount` above zero it becomes the home progress bed: one flower per
/// solved task on a strip of soil that runs only as far as the flowers, planted in groups of
/// five with a larger gap after every ten (like the dot frames), capped at
/// `GardenTuning.bloomCap` and at what fits the width.
///
/// `width` fixes the strip's width; nil fills the container. The height is whatever the
/// container proposes (76 pt for the bed, the footer's height under the sound button).
/// Newly solved tasks grow from the soil when the home screen reappears; a reset clears the
/// bed at once. Transitions run without animation under Reduce Motion. The bed is decoration:
/// `home.solvedTotal` remains the only statement of progress.
struct GardenMeadow: View {
    let width: CGFloat?
    let bloomCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Int?
    @State private var isOnScreen = false

    init(width: CGFloat? = nil, bloomCount: Int) {
        self.width = width
        self.bloomCount = max(0, bloomCount)
    }

    private var growth: Animation? {
        reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let bed = BedLayout(width: size.width, height: size.height)
            let visible = min(shown ?? bloomCount, GardenTuning.bloomCap, bed.capacity)
            ZStack(alignment: .topLeading) {
                MeadowGround(size: size)
                    .equatable()
                if visible > 0 {
                    // The soil runs only as far as the planted flowers, so the bed never
                    // looks like an empty track waiting to be filled.
                    Capsule()
                        .fill(GardenStyle.soilLight)
                        .overlay {
                            Capsule().strokeBorder(GardenStyle.soil, lineWidth: 1)
                        }
                        .frame(width: bed.soilWidth(planted: visible), height: 9)
                        .position(x: bed.soilStart + bed.soilWidth(planted: visible) / 2, y: bed.baseY + 0.5)
                        .transition(.opacity)
                }
                ForEach(0..<visible, id: \.self) { index in
                    BedFlower(index: index)
                        .position(bed.position(of: index))
                        .zIndex(BedFlower.isBackRow(index) ? 0 : 1)
                        .transition(.scale(scale: 0.1, anchor: .bottom).combined(with: .opacity))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
        .frame(width: width)
        .onAppear {
            isOnScreen = true
            if let current = shown {
                if bloomCount > current {
                    withAnimation(growth) { shown = bloomCount }
                }
            } else {
                shown = bloomCount
            }
        }
        .onDisappear { isOnScreen = false }
        .onChange(of: bloomCount) { _, newValue in
            guard let current = shown else { return }
            if newValue < current {
                withAnimation(Motion.quick(reduceMotion)) { shown = newValue }
            } else if newValue > current, isOnScreen {
                withAnimation(growth) { shown = newValue }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Where the bed's flowers stand: groups of five with a larger gap after every ten,
/// alternating a front and a back row so the bed looks planted rather than lined up.
private struct BedLayout {
    let width: CGFloat
    let height: CGFloat

    static let margin: CGFloat = 22
    private static let cell: CGFloat = 15
    private static let fiveGap: CGFloat = 7
    private static let tenGap: CGFloat = 12

    /// The soil line the front row stands on.
    var baseY: CGFloat { height - 17 }

    /// Leading edge of the soil strip.
    var soilStart: CGFloat { Self.margin - 8 }

    /// Length of the soil strip under `planted` flowers (at least one).
    func soilWidth(planted: Int) -> CGFloat {
        max(0, x(of: max(planted, 1) - 1) + 14 - soilStart)
    }

    func x(of index: Int) -> CGFloat {
        let tens = index / 10
        let fives = index / 5 - tens
        return Self.margin + 8
            + CGFloat(index) * Self.cell
            + CGFloat(fives) * Self.fiveGap
            + CGFloat(tens) * Self.tenGap
    }

    /// Centre of flower `index`'s frame (its base sits 1.5 pt above the frame's bottom).
    func position(of index: Int) -> CGPoint {
        let size = BedFlower.size(for: index)
        let lift: CGFloat = BedFlower.isBackRow(index) ? 5 : 0
        return CGPoint(x: x(of: index), y: baseY - lift - size / 2 + 1.5)
    }

    /// How many flowers fit before the trailing margin, at most the bloom cap.
    var capacity: Int {
        var count = 0
        while count < GardenTuning.bloomCap, x(of: count) + 12 <= width - Self.margin {
            count += 1
        }
        return count
    }
}

/// One bed flower: daisies and tulips alternate, colours cycle, odd indices stand in the back row.
private struct BedFlower: View {
    let index: Int

    private static let daisyPetals: [Color] = [GardenStyle.petalPink, Color.white.opacity(0.95), GardenStyle.lilac]
    private static let tulipPetals: [Color] = [GardenStyle.petalRed, GardenStyle.lilac, GardenStyle.orangeSoft]

    static func isBackRow(_ index: Int) -> Bool { index % 2 == 1 }

    static func size(for index: Int) -> CGFloat { isBackRow(index) ? 30 : 27 }

    var body: some View {
        let size = Self.size(for: index)
        Canvas { context, canvasSize in
            let base = CGPoint(x: canvasSize.width / 2, y: canvasSize.height - 1.5)
            let colourIndex = (index / 2) % 3
            if index % 2 == 0 {
                GardenFlower.drawDaisy(in: &context, base: base, size: size, petal: Self.daisyPetals[colourIndex], sway: .zero)
            } else {
                GardenFlower.drawTulip(in: &context, base: base, size: size, petal: Self.tulipPetals[colourIndex], sway: .zero)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// The grass itself: an opaque hillMid back, hillNear in front of a wavy edge and sparse
/// tufts (never in the centre 40 % of the width, where the sound capsule rests).
/// Equatable, so it is drawn once per size.
private struct MeadowGround: View, Equatable {
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .color(GardenStyle.hillMid))

            func edgeY(_ x: CGFloat) -> CGFloat {
                0.48 * h + 3 * sin(x / 34) + 1.5 * sin(x / 9 + 1)
            }

            var grass = Path()
            grass.move(to: CGPoint(x: 0, y: edgeY(0)))
            var x: CGFloat = 0
            while x < w {
                x = min(x + 6, w)
                grass.addLine(to: CGPoint(x: x, y: edgeY(x)))
            }
            grass.addLine(to: CGPoint(x: w, y: h))
            grass.addLine(to: CGPoint(x: 0, y: h))
            grass.closeSubpath()
            context.fill(grass, with: .color(GardenStyle.hillNear))

            let tuftSizes: [CGFloat] = [11, 14, 9]
            var k = 0
            while true {
                let tuftX = 28 + CGFloat(k) * 96 + CGFloat((k * 5) % 7 - 3) * 4
                if tuftX > w - 20 { break }
                if tuftX < 0.3 * w || tuftX > 0.7 * w {
                    GardenFlower.drawTuft(
                        in: &context,
                        base: CGPoint(x: tuftX, y: edgeY(tuftX) + 4),
                        size: tuftSizes[k % tuftSizes.count],
                        sway: .zero
                    )
                }
                k += 1
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
