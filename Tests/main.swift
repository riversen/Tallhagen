import Foundation

// Standalone runner: `./Tests/run.sh` compiles MathLogic.swift, GameSessions.swift, SoundRecipes.swift and the shared
// checks with plain swiftc. Pass `--rounds N` to change the randomized round count per level.

var rounds = 10_000
if let index = CommandLine.arguments.firstIndex(of: "--rounds"),
   index + 1 < CommandLine.arguments.count,
   let value = Int(CommandLine.arguments[index + 1]) {
    rounds = max(1, value)
}
let seed: UInt64 = 2026

let checker = LogicChecker { message in
    FileHandle.standardError.write(Data(("FAIL: " + message + "\n").utf8))
}
LogicChecks.runAll(checker, rounds: rounds, seed: seed)

if checker.failures > 0 {
    print("Failed: \(checker.failures) of \(checker.total) checks (seed \(seed), \(rounds) rounds per level).")
    exit(1)
}
print("Passed: \(checker.total) checks, including \(rounds) seeded randomized rounds per level for all three generators, per range for the bar tasks, per level and task for place value and per phase for the balance, every target up to each level's maximum (40, 100 and 9999 included), session state machines, the island map, stars and workshop limits, and the sound cues (seed \(seed)).")
