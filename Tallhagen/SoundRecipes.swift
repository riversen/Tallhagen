import Foundation

// The quiet sounds that accompany a choice, a change and a success (version 12).
//
// They are synthesised here from a few lines of arithmetic instead of being recorded: every
// cue is original, the app ships no sound files, and `Tests/run.sh` checks the waveforms like
// the number rules (loudness, length, silent start and end, no DC offset, reproducibility).
// `SoundCuePlayer` in Theme.swift turns them into audio buffers and plays them.
//
// All cues stay far below the speech: their peaks lie between about -28 and -22 dBFS, they
// start and end in silence and none lasts more than two seconds. Nothing is shrill: the noise
// in paper, tick, knock and applause is low-pass filtered, and every tone stays below about
// 4.2 kHz. Foundation only, so the checks run with plain swiftc.

/// One of the app's sound cues.
enum SoundCue: String, CaseIterable {
    /// A choice: opening a game, the map or a map task, the next task, going back. A soft
    /// slide of paper.
    case paper
    /// A change: a piece placed, a bar moved, a number stepped up or down. A small wooden tick.
    case tick
    /// A refused move or a wrong answer: a soft, low, neutral knock, never a buzzer.
    case knock
    /// A solved task: three soft rising mallet notes.
    case chime
    /// A finished task on Talløyene: a faint, distant ripple of applause.
    case applause

    /// The highest sample value of the cue, full scale being 1 (0.05 is about -26 dBFS).
    var peak: Float {
        switch self {
        case .paper: return 0.04
        case .tick: return 0.05
        case .knock: return 0.05
        case .chime: return 0.075
        case .applause: return 0.045
        }
    }

    /// How many slightly different versions exist, so a quick series does not sound mechanical.
    var variants: Int {
        switch self {
        case .paper: return 3
        case .tick: return 4
        case .knock, .chime, .applause: return 1
        }
    }

    /// The shortest time between two plays of this cue; a faster series is thinned out
    /// (dragging the Del opp slider ticks at most about twenty times a second).
    var minimumInterval: TimeInterval {
        switch self {
        case .paper: return 0.12
        case .tick: return 0.045
        case .knock: return 0.15
        case .chime: return 0.3
        case .applause: return 1.5
        }
    }
}

/// Decides whether a cue may sound now: never while sound is off, and not again sooner than the
/// cue's minimum interval. A refused play does not count as played.
struct SoundCueGate {
    private var lastPlayed: [SoundCue: TimeInterval] = [:]

    mutating func allows(_ cue: SoundCue, soundOn: Bool, at time: TimeInterval) -> Bool {
        guard soundOn else { return false }
        if let last = lastPlayed[cue], time - last < cue.minimumInterval { return false }
        lastPlayed[cue] = time
        return true
    }
}

/// The synthesis recipes. Every call with the same cue and variant returns the same samples
/// (mono, 32-bit float, `sampleRate`).
enum SoundRecipes {
    static let sampleRate = 44_100.0

    static func samples(for cue: SoundCue, variant: Int = 0) -> [Float] {
        let variant = max(0, variant) % cue.variants
        let raw: [Float]
        switch cue {
        case .paper: raw = paper(variant: variant)
        case .tick: raw = tick(variant: variant)
        case .knock: raw = knock()
        case .chime: raw = chime()
        case .applause: raw = applause()
        }
        return finished(raw, peak: cue.peak)
    }

    // MARK: Recipes

    /// Band-limited noise with a fibrous texture whose brightness falls as it slides: a sheet
    /// of paper drawn softly over another.
    private static func paper(variant: Int) -> [Float] {
        let duration = 0.2
        let count = sampleCount(duration)
        var noise = CueNoise(seed: 0x9A9E_0000 &+ UInt64(variant))
        var texture = CueNoise(seed: 0x7E47_0000 &+ UInt64(variant))
        // Three one-pole low-passes in a row (18 dB per octave) keep the rustle soft, not hissy.
        var first: Float = 0, second: Float = 0, third: Float = 0, highPassState: Float = 0, fibre: Float = 0
        let highPassCoefficient = lowPassCoefficient(500)
        let fibreCoefficient = lowPassCoefficient(45)
        var out = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let t = time(index)
            // The cut-off glides from 3.6 kHz down to 1.8 kHz.
            let coefficient = lowPassCoefficient(3_600 - 1_800 * (t / duration))
            first += coefficient * (noise.next() - first)
            second += coefficient * (first - second)
            third += coefficient * (second - third)
            highPassState += highPassCoefficient * (third - highPassState)
            let band = third - highPassState
            fibre += fibreCoefficient * (texture.next() - fibre)
            let grain = 0.62 + 0.38 * Float(min(1, max(-1, Double(fibre) * 6)))
            let envelope = raisedCosine(t / 0.028) * raisedCosine((duration - t) / 0.125)
            out[index] = band * grain * Float(envelope)
        }
        return out
    }

    /// A small wooden tick: a damped tone with a lower body partial and a soft noise touch at the
    /// very start. The four variants differ slightly in pitch.
    private static func tick(variant: Int) -> [Float] {
        let pitches = [1_010.0, 1_075.0, 1_145.0, 1_220.0]
        let frequency = pitches[variant % pitches.count]
        let count = sampleCount(0.08)
        var noise = CueNoise(seed: 0x71C4_0000 &+ UInt64(variant))
        var touch: Float = 0
        let touchCoefficient = lowPassCoefficient(2_800)
        var out = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let t = time(index)
            let body = sin(2 * .pi * frequency * t) * exp(-t / 0.0105)
                + 0.42 * sin(2 * .pi * frequency * 0.52 * t) * exp(-t / 0.017)
            touch += touchCoefficient * (noise.next() - touch)
            let transient = Double(touch) * exp(-t / 0.0014) * 0.9
            out[index] = Float((body + transient) * raisedCosine(t / 0.0007))
        }
        return out
    }

    /// A soft, low knock: a damped low tone with one inharmonic partial, like a fingertip on
    /// a wooden table. Pitched at 300 Hz, because small iPad speakers give little below that.
    private static func knock() -> [Float] {
        let fundamental = 300.0
        let count = sampleCount(0.14)
        var noise = CueNoise(seed: 0x4B0C_0001)
        var touch: Float = 0
        let touchCoefficient = lowPassCoefficient(1_600)
        var out = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let t = time(index)
            let body = sin(2 * .pi * fundamental * t) * exp(-t / 0.03)
                + 0.5 * sin(2 * .pi * fundamental * 2.61 * t) * exp(-t / 0.012)
            touch += touchCoefficient * (noise.next() - touch)
            let transient = Double(touch) * exp(-t / 0.0022) * 0.6
            out[index] = Float((body + transient) * raisedCosine(t / 0.0028))
        }
        return out
    }

    /// Three soft mallet notes rising through a major triad (E, G, C), each with a warm second
    /// partial and a brief wooden fourth.
    private static func chime() -> [Float] {
        let duration = 1.05
        let count = sampleCount(duration)
        let notes: [(frequency: Double, onset: Double, gain: Double)] = [
            (659.255, 0.0, 0.82), (783.991, 0.075, 0.86), (1_046.502, 0.15, 1.0),
        ]
        var out = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let t = time(index)
            var value = 0.0
            for note in notes where t >= note.onset {
                let local = t - note.onset
                let f = note.frequency
                let tone = sin(2 * .pi * f * local) * exp(-local / 0.30)
                    + 0.16 * sin(2 * .pi * 2 * f * local) * exp(-local / 0.11)
                    + 0.06 * sin(2 * .pi * 4 * f * local) * exp(-local / 0.045)
                value += note.gain * tone * raisedCosine(local / 0.006)
            }
            out[index] = Float(value * raisedCosine((duration - t) / 0.12))
        }
        return out
    }

    /// A faint, distant ripple of applause: about a hundred short filtered noise claps whose
    /// density swells and fades, softened further by a low-pass filter.
    private static func applause() -> [Float] {
        let duration = 1.9
        let count = sampleCount(duration)
        var random = CueNoise(seed: 0xA991_A05E)
        var out = [Float](repeating: 0, count: count)
        let clapLength = sampleCount(0.014)
        let peakRate = 75.0 // claps per second at the fullest moment
        var t = 0.0
        while true {
            // Poisson process thinned by the density envelope.
            let uniform = Double(random.next()) * 0.5 + 0.5
            t += -log(max(uniform, 1e-9)) / peakRate
            if t >= duration - 0.05 { break }
            let density = raisedCosine(t / 0.15) * raisedCosine((duration - t) / 1.0)
            guard Double(random.next()) * 0.5 + 0.5 < density else { continue }
            let start = Int(t * sampleRate)
            let amplitude = Float(0.35 + 0.65 * (Double(random.next()) * 0.5 + 0.5))
            let highPassCoefficient = lowPassCoefficient(700 + 400 * (Double(random.next()) * 0.5 + 0.5))
            let lowPassCut = lowPassCoefficient(1_600 + 1_000 * (Double(random.next()) * 0.5 + 0.5))
            var lowPass: Float = 0, highPassState: Float = 0
            for offset in 0..<clapLength where start + offset < count {
                let local = Double(offset) / sampleRate
                lowPass += lowPassCut * (random.next() - lowPass)
                highPassState += highPassCoefficient * (lowPass - highPassState)
                let envelope = raisedCosine(local / 0.0004) * exp(-local / 0.0032)
                out[start + offset] += (lowPass - highPassState) * amplitude * Float(envelope)
            }
        }
        // Distance: a gentle low-pass over the whole crowd, then the overall swell.
        var smooth: Float = 0
        let distance = lowPassCoefficient(3_000)
        for index in 0..<count {
            smooth += distance * (out[index] - smooth)
            let t = time(index)
            out[index] = smooth * Float(raisedCosine(t / 0.1) * raisedCosine((duration - t) / 0.7))
        }
        return out
    }

    // MARK: Helpers

    /// Removes any offset, scales to the cue's peak and guarantees a silent first and last sample.
    private static func finished(_ samples: [Float], peak: Float) -> [Float] {
        guard !samples.isEmpty else { return samples }
        let mean = samples.reduce(0, +) / Float(samples.count)
        var out = samples.map { $0 - mean }
        // A short fade at both ends brings the very first and last sample to zero.
        let edge = min(sampleCount(0.002), out.count / 4)
        if edge > 0 {
            for index in 0..<edge {
                let gain = Float(raisedCosine(Double(index) / Double(edge)))
                out[index] *= gain
                out[out.count - 1 - index] *= gain
            }
        }
        let loudest = out.reduce(0) { max($0, abs($1)) }
        guard loudest > 0 else { return out }
        let scale = peak / loudest
        return out.map { $0 * scale }
    }

    private static func sampleCount(_ seconds: Double) -> Int {
        Int((seconds * sampleRate).rounded())
    }

    private static func time(_ index: Int) -> Double {
        Double(index) / sampleRate
    }

    /// 0 at or below 0, 1 at or above 1, a smooth half cosine in between.
    private static func raisedCosine(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        return 0.5 - 0.5 * cos(.pi * x)
    }

    /// The coefficient of a one-pole low-pass filter with the given cut-off.
    private static func lowPassCoefficient(_ hertz: Double) -> Float {
        Float(1 - exp(-2 * .pi * hertz / sampleRate))
    }
}

/// A tiny deterministic noise source (xorshift64*), so every cue sounds the same on every run.
struct CueNoise {
    private var state: UInt64

    init(seed: UInt64) {
        state = (seed &* 0x9E37_79B9_7F4A_7C15) | 1
    }

    /// The next value, uniform in [-1, 1).
    mutating func next() -> Float {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        let value = state &* 2_685_821_657_736_338_717
        return Float(value >> 40) / Float(1 << 23) - 1
    }
}
