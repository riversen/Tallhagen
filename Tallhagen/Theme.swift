import SwiftUI
import AVFoundation
import UIKit

// Design tokens, the activity catalog, persistence keys, speech, haptics and motion helpers.
// Keep voice handling in one place; use only Apple APIs available on iPadOS.

enum GardenStyle {
    static let paper = Color(red: 0.973, green: 0.970, blue: 0.941)
    static let ink = Color(red: 0.143, green: 0.203, blue: 0.251)
    // Tints are dark enough for small text on white and paper (WCAG AA, at least 4.5:1),
    // except orange (4.1:1), which is reserved for large numerals, icons and fills.
    static let muted = Color(red: 0.33, green: 0.39, blue: 0.41)
    static let teal = Color(red: 0.0, green: 0.48, blue: 0.44)
    static let orange = Color(red: 0.80, green: 0.36, blue: 0.14)
    static let purple = Color(red: 0.47, green: 0.34, blue: 0.74)
    static let blue = Color(red: 0.17, green: 0.45, blue: 0.72)
    static let yellow = Color(red: 0.980, green: 0.772, blue: 0.322)
    static let lightLine = Color(red: 0.861, green: 0.891, blue: 0.868)
}

extension Font {
    /// Child-facing sentences and labels. Follows Dynamic Type in the app's rounded style.
    static func garden(_ style: Font.TextStyle, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    /// Big numerals and display headings that keep a fixed size so quantities stay countable
    /// next to their dots. Pair with `minimumScaleFactor` where space is tight.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Where the hosted privacy policy lives: GitHub Pages, from `docs/privacy.html` in the public
/// repository riversen/Tallhagen (the text of `AppStore/privacy-policy/index.html` with the date
/// and contact filled in). Settings shows it as plain text, never as a link, because the app
/// opens nothing outside itself. `Tools/release.sh` refuses to archive unless it is an https
/// address, since App Review Guideline 5.1.1(i) wants the policy reachable in the app.
enum PrivacyPolicy {
    static let address = "https://riversen.github.io/Tallhagen/privacy.html"
}

/// UserDefaults keys. Do not rename them: children would lose their level and solved count.
enum StorageKey {
    static let learningLevel = "learningLevel"
    static let speakNorwegian = "speakNorwegian"
    static let solvedTotal = "solvedTotal"
    /// Version 8: stars per map node as "nodeID=stars,…" (see `MapProgress`). Unlocks are derived
    /// from it, so no second key exists; Settings resets it separately from `solvedTotal`.
    static let islandStars = "islandStars"
}

extension LearningLevel {
    /// The level saved on this iPad, or the fallback when nothing valid is stored.
    static func stored(in defaults: UserDefaults = .standard) -> LearningLevel {
        resolve(defaults.integer(forKey: StorageKey.learningLevel))
    }
}

enum GameKind: String, CaseIterable, Identifiable, Hashable {
    case build, pair, split, workshop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .build: return "Bygg tallet"
        case .pair: return "Finn tallvennen"
        case .split: return "Del opp"
        case .workshop: return "Tallverkstedet"
        }
    }

    var subtitle: String {
        switch self {
        case .build: return "Legg sammen brikker til riktig tall"
        case .pair: return "Hvilket tall mangler?"
        case .split: return "Finn to deler av samme tall"
        case .workshop: return "Utforsk tall helt fritt"
        }
    }

    var tint: Color {
        switch self {
        case .build: return GardenStyle.teal
        case .pair: return GardenStyle.orange
        case .split: return GardenStyle.purple
        case .workshop: return GardenStyle.blue
        }
    }

    /// Stable identifier for UI tests.
    var accessibilityIdentifier: String { "home.game.\(rawValue)" }
}

struct BouncyButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Motion.quick(reduceMotion), value: configuration.isPressed)
    }
}

/// Brief, purposeful animations that step aside when Reduce Motion is on.
///
/// Every spatial animation in the app (springs, scale, hops, swaying scenery, symbol effects)
/// is gated through these helpers or through an explicit Reduce Motion branch. The single
/// permitted exception is a 0.4 s opacity-only crossfade of creature eyes, highlights and
/// halos in GardenCreatures.swift: the HIG asks for motion to be replaced by a fade, not for
/// a state change to appear with no transition at all.
enum Motion {
    static func spring(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.82)
    }

    static func quick(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.2)
    }
}

/// What the voice chooser knows about one installed voice. Plain values, so the choice can be
/// tested without real AVFoundation voices.
struct VoiceCandidate: Equatable {
    let identifier: String
    /// BCP 47 tag as the system reports it, for example `nb-NO`.
    let language: String
    /// 1 = default (compact), 2 = enhanced, 3 = premium.
    let quality: Int
    /// False for Personal Voice and novelty voices, which never read to a child.
    let isUsable: Bool
}

/// On-device Norwegian speech. Uses the best Norwegian voice installed on the iPad: Bokmål
/// (`nb`) before any other Norwegian tag, then Premium over Enhanced over the compact default,
/// re-checked whenever the installed voices change (for example after a download in
/// Settings › Accessibility › Read & Speak › Voices). Siri's voices are not available to
/// apps. If no Norwegian voice is installed, the system default voice reads the phrase (and
/// may mispronounce it). Automatic speech steps aside while VoiceOver runs, because VoiceOver
/// already reads the same text through its announcements. The Les opp oppgaven and Les opp
/// regnestykket buttons speak anyway (`deferToVoiceOver: false`); `narrate`, behind Les opp
/// valgene and the map's Les opp, stays silent under VoiceOver, which reads menus itself.
///
/// Menus use `narrate`: an intro sentence followed by one phrase per choice. While a choice
/// is being spoken, `narratedItem` holds its identifier so the matching card can glow.
final class NorwegianVoice: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = NorwegianVoice()
    private let synthesizer = AVSpeechSynthesizer()

    /// Identifier of the menu choice being spoken right now, or nil between choices and when idle.
    @Published private(set) var narratedItem: String?
    private var narrationItems: [ObjectIdentifier: String] = [:]

    private var cachedVoice: AVSpeechSynthesisVoice?
    private var voiceNeedsRefresh = true

    /// The best installed Norwegian voice, chosen again after the installed voices change.
    private var voice: AVSpeechSynthesisVoice? {
        if voiceNeedsRefresh {
            cachedVoice = Self.installedNorwegianVoice()
            voiceNeedsRefresh = false
        }
        return cachedVoice
    }

    private override init() {
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(availableVoicesDidChange),
            name: AVSpeechSynthesizer.availableVoicesDidChangeNotification,
            object: nil
        )
    }

    @objc private func availableVoicesDidChange() {
        voiceNeedsRefresh = true
    }

    // MARK: Voice choice

    /// Picks the best Norwegian voice among `candidates`: Bokmål (`nb`) before any other
    /// Norwegian tag (`nn`, `no`), then the highest quality. Nil when none is installed.
    static func bestNorwegianVoice(among candidates: [VoiceCandidate]) -> VoiceCandidate? {
        candidates
            .filter { $0.isUsable && isNorwegian($0.language) }
            .max { lhs, rhs in
                (isBokmal(lhs.language) ? 1 : 0, lhs.quality) < (isBokmal(rhs.language) ? 1 : 0, rhs.quality)
            }
    }

    static func isNorwegian(_ language: String) -> Bool {
        let tag = language.lowercased()
        return tag.hasPrefix("nb") || tag.hasPrefix("nn") || tag.hasPrefix("no")
    }

    static func isBokmal(_ language: String) -> Bool {
        language.lowercased().hasPrefix("nb")
    }

    private static func installedNorwegianVoice() -> AVSpeechSynthesisVoice? {
        let installed = AVSpeechSynthesisVoice.speechVoices()
        let candidates = installed.map { voice in
            VoiceCandidate(
                identifier: voice.identifier,
                language: voice.language,
                quality: qualityRank(voice.quality),
                isUsable: voice.voiceTraits.isDisjoint(with: [.isPersonalVoice, .isNoveltyVoice])
            )
        }
        if let best = bestNorwegianVoice(among: candidates),
           let voice = installed.first(where: { $0.identifier == best.identifier }) {
            return voice
        }
        return AVSpeechSynthesisVoice(language: "nb-NO")
    }

    private static func qualityRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium: return 3
        case .enhanced: return 2
        case .default: return 1
        @unknown default: return 0
        }
    }

    private func makeUtterance(_ phrase: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = voice
        utterance.rate = 0.48
        return utterance
    }

    func say(_ phrase: String, enabled: Bool, deferToVoiceOver: Bool = true) {
        guard enabled, !phrase.isEmpty else { return }
        if deferToVoiceOver, UIAccessibility.isVoiceOverRunning { return }
        stop()
        synthesizer.speak(makeUtterance(phrase))
    }

    /// Speaks after whatever is being said now instead of cutting it off: the completion
    /// sentence of a map node follows the last task's success sentence. Skipped like `say`.
    func sayAfterCurrent(_ phrase: String, enabled: Bool) {
        guard enabled, !phrase.isEmpty, !UIAccessibility.isVoiceOverRunning else { return }
        synthesizer.speak(makeUtterance(phrase))
    }

    /// Reads a menu aloud: `intro` first, then every choice. Skipped when speech is off or
    /// VoiceOver is running (VoiceOver reads menus itself).
    func narrate(intro: String?, items: [(id: String, phrase: String)], enabled: Bool) {
        guard enabled, !items.isEmpty, !UIAccessibility.isVoiceOverRunning else { return }
        stop()
        if let intro, !intro.isEmpty {
            synthesizer.speak(makeUtterance(intro))
        }
        for item in items {
            let utterance = makeUtterance(item.phrase)
            utterance.preUtteranceDelay = 0.2
            narrationItems[ObjectIdentifier(utterance)] = item.id
            synthesizer.speak(utterance)
        }
    }

    /// Stops everything, including a running narration.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        narrationItems.removeAll()
        if narratedItem != nil { narratedItem = nil }
    }

    // MARK: AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let item = narrationItems[ObjectIdentifier(utterance)]
        DispatchQueue.main.async { self.narratedItem = item }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        narrationEnded(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        narrationEnded(utterance)
    }

    private func narrationEnded(_ utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.narrationItems[ObjectIdentifier(utterance)] = nil
            if self.narratedItem != nil { self.narratedItem = nil }
        }
    }
}

enum TouchFeedback {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func gentleWarning() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

/// Plays the quiet sound cues of `SoundRecipes` (version 12): a paper slide for a choice, a tick
/// for a change, a soft knock for a refused move, a chime for a solved task and a faint applause
/// for a finished task on Talløyene. iPads have no haptic engine, so these sounds are what makes
/// a tap feel answered there. They follow the switch of the automatic speech (the sound button
/// and «Les opp på norsk», key `speakNorwegian`): with sound off nothing plays.
///
/// The audio session is ambient, so the cues and the speech mix with other apps' audio instead
/// of stopping it, and they respect the iPad's silent mode. The cues are rendered off the main
/// thread at launch; the engine starts with the first cue and pauses after six quiet seconds
/// and in the background, and it is rebuilt if the iPad's media services restart. Call `play` on
/// the main thread.
final class SoundCuePlayer: NSObject, @unchecked Sendable {
    static let shared = SoundCuePlayer()

    private var engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundRecipes.sampleRate, channels: 1)
    private var players: [AVAudioPlayerNode] = []
    /// When each voice finishes its cue (system uptime), so a new cue takes a free voice and never
    /// cuts a chime short.
    private var busyUntil: [TimeInterval] = []
    private var buffers: [SoundCue: [AVAudioPCMBuffer]] = [:]
    private var lastVariant: [SoundCue: Int] = [:]
    private var gate = SoundCueGate()
    private var idlePause: DispatchWorkItem?
    private var isPrepared = false

    /// Sets the ambient audio session and renders the cues. Called once, at launch.
    func prepare() {
        guard !isPrepared else { return }
        isPrepared = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseEngine),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mediaServicesWereReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        DispatchQueue.global(qos: .utility).async {
            var rendered: [SoundCue: [[Float]]] = [:]
            for cue in SoundCue.allCases {
                rendered[cue] = (0..<cue.variants).map { SoundRecipes.samples(for: cue, variant: $0) }
            }
            let result = rendered
            DispatchQueue.main.async { self.install(result) }
        }
    }

    /// Plays `cue`, unless sound is off or the same cue sounded a moment ago. Pass `enabled`
    /// when the caller already holds the sound setting; otherwise the stored setting is read.
    func play(_ cue: SoundCue, enabled: Bool? = nil) {
        let soundOn = enabled ?? Self.isSoundOn()
        let now = ProcessInfo.processInfo.systemUptime
        guard let variants = buffers[cue], !variants.isEmpty, !players.isEmpty,
              gate.allows(cue, soundOn: soundOn, at: now) else { return }
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        // A random variant, never the same one twice in a row, so a series does not form a tune.
        var variant = Int.random(in: 0..<variants.count)
        if variants.count > 1, variant == lastVariant[cue] { variant = (variant + 1) % variants.count }
        lastVariant[cue] = variant
        let buffer = variants[variant]
        // A free voice if there is one; otherwise the one that finishes first.
        let index = busyUntil.firstIndex { $0 <= now }
            ?? busyUntil.indices.min { busyUntil[$0] < busyUntil[$1] } ?? 0
        busyUntil[index] = now + Double(buffer.frameLength) / buffer.format.sampleRate
        let player = players[index]
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
        schedulePause()
    }

    /// Silences a cue that is still sounding (the chime or the applause) when sound is turned off.
    func stopAll() {
        guard engine.isRunning else { return }
        players.forEach { $0.stop() }
        busyUntil = busyUntil.map { _ in 0 }
    }

    /// The stored sound setting, shared with the sound button and «Les opp på norsk»; on by default.
    static func isSoundOn(in defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: StorageKey.speakNorwegian) != nil else { return true }
        return defaults.bool(forKey: StorageKey.speakNorwegian)
    }

    private func install(_ rendered: [SoundCue: [[Float]]]) {
        guard let format, players.isEmpty else { return }
        for (cue, variants) in rendered {
            buffers[cue] = variants.compactMap { Self.buffer(from: $0, format: format) }
        }
        attachPlayers()
        // Allocate the render resources now, so the first cue only has to start the hardware.
        engine.prepare()
    }

    /// Four voices, so a tick can sound while a chime is still ringing.
    private func attachPlayers() {
        guard let format else { return }
        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
            busyUntil.append(0)
        }
    }

    private static func buffer(from samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        for (index, sample) in samples.enumerated() {
            channel[index] = sample
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        return buffer
    }

    /// Pauses the engine after six quiet seconds, so no audio hardware stays busy while the child
    /// thinks; the next cue starts it again.
    private func schedulePause() {
        idlePause?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.pauseEngine() }
        idlePause = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: work)
    }

    @objc private func pauseEngine() {
        idlePause?.cancel()
        idlePause = nil
        // A cue cut off by the background must not resume when the next cue starts the engine.
        players.forEach { $0.stop() }
        busyUntil = busyUntil.map { _ in 0 }
        if engine.isRunning { engine.pause() }
    }

    /// After the iPad's media services restart, the engine and its voices are gone and the session
    /// has lost its settings: set the category again and build a new engine. The buffers stay valid.
    @objc private func mediaServicesWereReset() {
        DispatchQueue.main.async {
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            self.idlePause?.cancel()
            self.idlePause = nil
            self.engine = AVAudioEngine()
            self.players = []
            self.busyUntil = []
            if !self.buffers.isEmpty { self.attachPlayers() }
        }
    }
}

/// Lets VoiceOver users hear feedback that appears on screen without moving focus.
/// High priority, so VoiceOver's own focus-change speech does not cut the sentence off.
enum VoiceOverAnnouncer {
    static func announce(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning, !text.isEmpty else { return }
        var message = AttributedString(text)
        message.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(message).post()
    }
}

/// Shared reaction to an answer outcome: haptics, a sound cue, VoiceOver announcement and optional
/// speech. The cue and the speech follow the same sound setting (`voiceEnabled`).
/// Views still own the solved counter, so incrementing it stays visible at the call site.
enum GameFeedback {
    static func react(to outcome: AnswerOutcome, feedback: String?, voiceEnabled: Bool) {
        switch outcome {
        case .solved:
            TouchFeedback.success()
            SoundCuePlayer.shared.play(.chime, enabled: voiceEnabled)
        case .progress:
            TouchFeedback.light()
            SoundCuePlayer.shared.play(.tick, enabled: voiceEnabled)
        case .rejected, .incorrect:
            TouchFeedback.gentleWarning()
            SoundCuePlayer.shared.play(.knock, enabled: voiceEnabled)
        case .ignored:
            return
        }
        guard let feedback else { return }
        VoiceOverAnnouncer.announce(feedback)
        NorwegianVoice.shared.say(feedback, enabled: voiceEnabled)
    }
}
