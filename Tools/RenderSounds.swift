import Foundation

// Writes Tallhagen's sound cues (Tallhagen/SoundRecipes.swift) to 16-bit WAV files for
// listening: one file per cue and variant, plus preview.wav with every cue in a row, half a
// second apart, and prints each cue's length, peak and RMS level. The files play at the app's
// own quiet level. Not part of any Xcode target. On a Mac:
//   swiftc -O Tallhagen/SoundRecipes.swift Tools/RenderSounds.swift -o /tmp/rendersounds
//   /tmp/rendersounds ~/Desktop/Tallhagen-sounds

@main
struct RenderSounds {
    static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 2 else {
            print("Usage: rendersounds <output folder>")
            exit(2)
        }
        let folder = URL(fileURLWithPath: (arguments[1] as NSString).expandingTildeInPath, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var preview: [Float] = []
        let gap = [Float](repeating: 0, count: Int(SoundRecipes.sampleRate * 0.5))
        for cue in SoundCue.allCases {
            for variant in 0..<cue.variants {
                let samples = SoundRecipes.samples(for: cue, variant: variant)
                let name = cue.variants > 1 ? "\(cue.rawValue)-\(variant + 1).wav" : "\(cue.rawValue).wav"
                try wav(samples).write(to: folder.appendingPathComponent(name))
                preview += samples + gap
                let peak = samples.reduce(Float(0)) { max($0, abs($1)) }
                let rms = (samples.reduce(Float(0)) { $0 + $1 * $1 } / Float(samples.count)).squareRoot()
                let seconds = Double(samples.count) / SoundRecipes.sampleRate
                print(String(format: "%@  %.3f s  peak %.1f dBFS  RMS %.1f dBFS",
                             name, seconds, 20 * log10(Double(peak)), 20 * log10(Double(rms))))
            }
        }
        try wav(preview).write(to: folder.appendingPathComponent("preview.wav"))
        print("Wrote \(folder.path)")
    }

    /// Mono 16-bit PCM WAV data at the recipes' sample rate.
    static func wav(_ samples: [Float]) -> Data {
        let rate = UInt32(SoundRecipes.sampleRate)
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let payload = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(36 + payload)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1)); append(rate); append(rate * 2)
        append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(payload)
        for sample in samples {
            append(Int16(max(-1, min(1, sample)) * Float(Int16.max)))
        }
        return data
    }
}
