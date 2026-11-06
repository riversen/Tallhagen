import Foundation
#if TALLHAGEN_XCTEST
@testable import Tallhagen
#endif

// Shared invariant checks for the math logic and the game sessions.
// `Tests/main.swift` runs them with plain `swiftc` (macOS or Linux), and the Xcode unit-test
// target runs the very same functions and reports each failure through XCTFail.

/// Collects check results. Unlike `assert`, these checks run in every build configuration.
final class LogicChecker {
    private let report: (String) -> Void
    private(set) var total = 0
    private(set) var failures = 0

    init(report: @escaping (String) -> Void) {
        self.report = report
    }

    func check(_ condition: Bool, _ message: @autoclosure () -> String) {
        total += 1
        if !condition {
            failures += 1
            report(message())
        }
    }

    func equal<T: Equatable>(_ actual: T, _ expected: T, _ label: @autoclosure () -> String) {
        check(actual == expected, "\(label()): expected \(expected), got \(actual)")
    }
}

enum LogicChecks {
    static let maximums = [10, 20, 30, 40, 100]

    // MARK: Puzzle validity

    static func checkBuild(_ c: LogicChecker, _ puzzle: BuildPuzzle, level: LearningLevel) {
        let range = BuildPuzzle.targetRange(for: level)
        c.check(range.contains(puzzle.target), "Build target \(puzzle.target) outside \(range) for \(level)")
        c.check(puzzle.target <= level.maximum, "Build target \(puzzle.target) above maximum \(level.maximum)")
        c.check(puzzle.solution.0 >= 1 && puzzle.solution.1 >= 1, "Build solution operands must be positive")
        c.check(puzzle.solution.0 + puzzle.solution.1 == puzzle.target, "Build solution must sum to target")
        c.equal(puzzle.pieces.count, 5, "Build piece count")
        c.equal(Set(puzzle.pieces.map(\.id)).count, 5, "Build piece identities must be distinct")
        c.check(puzzle.pieces.allSatisfy { (1..<puzzle.target).contains($0.value) },
                "Build pieces must be positive and below target \(puzzle.target)")
        // Always two checks (one per operand) so the total check count is reproducible.
        let requiredCount = puzzle.solution.0 == puzzle.solution.1 ? 2 : 1
        for number in [puzzle.solution.0, puzzle.solution.1] {
            c.check(puzzle.pieces.filter { $0.value == number }.count >= requiredCount,
                    "Build pieces must contain the solution value \(number)")
        }
        c.check(BuildPuzzle.completion(for: puzzle.target, from: puzzle.pieces) != nil,
                "Build puzzle \(puzzle.target) must be solvable from its pieces")
    }

    static func checkPair(_ c: LogicChecker, _ puzzle: PairPuzzle, level: LearningLevel) {
        let range = PairPuzzle.targetRange(for: level)
        c.check(range.contains(puzzle.target), "Pair target \(puzzle.target) outside \(range) for \(level)")
        c.check(puzzle.given >= 1 && puzzle.answer >= 1, "Pair operands must be positive")
        c.check(puzzle.given + puzzle.answer == puzzle.target, "Pair operands must sum to target")
        c.equal(puzzle.choices.count, 4, "Pair choice count")
        c.equal(Set(puzzle.choices).count, 4, "Pair choices must be distinct")
        c.check(puzzle.choices.allSatisfy { (1..<puzzle.target).contains($0) },
                "Pair choices must be positive and below target \(puzzle.target)")
        c.equal(puzzle.choices.filter { $0 == puzzle.answer }.count, 1, "Pair answer must appear exactly once")
    }

    static func checkSplit(_ c: LogicChecker, _ puzzle: SplitPuzzle, level: LearningLevel) {
        let range = SplitPuzzle.totalRange(for: level)
        c.check(range.contains(puzzle.total), "Split total \(puzzle.total) outside \(range) for \(level)")
        c.check((1..<puzzle.total).contains(puzzle.wantedLeft), "Split wantedLeft must be 1...total-1")
        c.check((1..<puzzle.total).contains(puzzle.wantedRight), "Split wantedRight must be 1...total-1")
        c.check(puzzle.wantedLeft + puzzle.wantedRight == puzzle.total, "Split groups must add back to total")
        c.check(puzzle.leftRange == 1...(puzzle.total - 1), "Split leftRange must exclude empty groups")
        c.check(puzzle.startingLeft != puzzle.wantedLeft, "Split must not start on the wanted answer")
        c.check(puzzle.leftRange.contains(puzzle.startingLeft), "Split starting value must be valid")
    }

    // MARK: Levels

    static func checkLevels(_ c: LogicChecker) {
        c.equal(LearningLevel.allCases.map(\.maximum), maximums, "Level maxima")
        c.equal(LearningLevel.allCases.map(\.title), ["Til 10", "Til 20", "Til 30", "Til 40", "Til 100"], "Level titles")
        c.equal(LearningLevel.allCases.map(\.rawValue), [1, 2, 3, 4, 5], "Keep saved level identifiers stable")
        c.equal(LearningLevel.fallback, .practice, "Fallback level")
        c.equal(LearningLevel.starterChoices.map(\.maximum), [20, 40, 100], "Starter choices")
        c.equal(LearningLevel.allCases.map(\.dotColumns), [5, 5, 5, 5, 10], "Rows of five up to 40, rows of ten at 100")
        for level in LearningLevel.allCases {
            c.equal(LearningLevel.resolve(level.rawValue), level, "Resolve stored value \(level.rawValue)")
            c.check(!level.detail.isEmpty, "Level detail text")
            c.check(!level.detail.lowercased().contains("minus"), "No activity teaches subtraction yet, so level copy must not promise it")
        }
        for unknown in [Int.min, -1, 0, 6, 40, 100, Int.max] {
            c.equal(LearningLevel.resolve(unknown), .practice, "Unknown stored level \(unknown) falls back")
        }
        c.equal(BuildPuzzle.targetRange(for: .start), 5...10, "Build range level 1")
        c.equal(BuildPuzzle.targetRange(for: .advanced), 8...40, "Build range level 4")
        c.equal(PairPuzzle.targetRange(for: .advanced), 5...40, "Pair range level 4")
        c.equal(SplitPuzzle.totalRange(for: .advanced), 5...40, "Split range level 4")
        c.equal(BuildPuzzle.targetRange(for: .hundred), 8...100, "Build range level 5")
        c.equal(PairPuzzle.targetRange(for: .hundred), 5...100, "Pair range level 5")
        c.equal(SplitPuzzle.totalRange(for: .hundred), 5...100, "Split range level 5")
    }

    // MARK: Generators

    /// Every generated puzzle must stay within its selected level. Seeded, so a failure is reproducible.
    static func checkRandomizedGeneration(_ c: LogicChecker, rounds: Int, seed: UInt64) {
        for level in LearningLevel.allCases {
            var generator = SeededGenerator(seed: seed &+ UInt64(level.rawValue))
            var seenMaximum = (build: false, pair: false, split: false)
            for _ in 0..<rounds {
                let build = BuildPuzzle.make(level: level, using: &generator)
                let pair = PairPuzzle.make(level: level, using: &generator)
                let split = SplitPuzzle.make(level: level, using: &generator)
                checkBuild(c, build, level: level)
                checkPair(c, pair, level: level)
                checkSplit(c, split, level: level)
                if build.target == level.maximum { seenMaximum.build = true }
                if pair.target == level.maximum { seenMaximum.pair = true }
                if split.total == level.maximum { seenMaximum.split = true }
            }
            if rounds >= 1_000 {
                c.check(seenMaximum.build && seenMaximum.pair && seenMaximum.split,
                        "Random generation at \(level) should reach the maximum \(level.maximum) within \(rounds) rounds")
            }
        }
        // A short unseeded run keeps the system random source covered too.
        for level in LearningLevel.allCases {
            for _ in 0..<50 {
                checkBuild(c, BuildPuzzle.make(level: level), level: level)
                checkPair(c, PairPuzzle.make(level: level), level: level)
                checkSplit(c, SplitPuzzle.make(level: level), level: level)
            }
        }
    }

    /// Every target in every range, including exactly 40, without relying on a lucky sample.
    static func checkExhaustiveTargets(_ c: LogicChecker) {
        var generator = SeededGenerator(seed: 4040)
        for level in LearningLevel.allCases {
            for target in BuildPuzzle.targetRange(for: level) {
                for _ in 0..<5 {
                    checkBuild(c, BuildPuzzle.make(level: level, target: target, using: &generator), level: level)
                }
            }
            for total in PairPuzzle.targetRange(for: level) {
                for _ in 0..<5 {
                    checkPair(c, PairPuzzle.make(level: level, target: total, using: &generator), level: level)
                    checkSplit(c, SplitPuzzle.make(level: level, total: total, using: &generator), level: level)
                }
            }
            // The random path can only reach the maximum if the ranges end there.
            let top = level.maximum
            c.equal(BuildPuzzle.targetRange(for: level).upperBound, top, "Build range reaches \(top)")
            c.equal(PairPuzzle.targetRange(for: level).upperBound, top, "Pair range reaches \(top)")
            c.equal(SplitPuzzle.totalRange(for: level).upperBound, top, "Split range reaches \(top)")
            // And a fixed seeded sample must actually produce it, independent of the CLI round count.
            var sampler = SeededGenerator(seed: 90 &+ UInt64(level.rawValue))
            var seen = (build: false, pair: false, split: false)
            for _ in 0..<2_000 {
                if BuildPuzzle.make(level: level, using: &sampler).target == top { seen.build = true }
                if PairPuzzle.make(level: level, using: &sampler).target == top { seen.pair = true }
                if SplitPuzzle.make(level: level, using: &sampler).total == top { seen.split = true }
            }
            c.check(seen.build, "Random build generation reaches \(top) in a seeded sample")
            c.check(seen.pair, "Random pair generation reaches \(top) in a seeded sample")
            c.check(seen.split, "Random split generation reaches \(top) in a seeded sample")
        }
        let forty = BuildPuzzle.make(level: .advanced, target: 40)
        c.check(forty.pieces.allSatisfy { $0.value <= 39 }, "Pieces for 40 stay at most 39")
        let pairForty = PairPuzzle.make(level: .advanced, target: 40)
        c.check(pairForty.given <= 39 && pairForty.answer <= 39, "Operands for 40 stay at most 39")
        let hundred = BuildPuzzle.make(level: .hundred, target: 100)
        c.check(hundred.pieces.allSatisfy { $0.value <= 99 }, "Pieces for 100 stay at most 99")
        let pairHundred = PairPuzzle.make(level: .hundred, target: 100)
        c.check(pairHundred.given <= 99 && pairHundred.answer <= 99, "Operands for 100 stay at most 99")
        c.equal(SplitPuzzle.make(level: .hundred, total: 100).leftRange, 1...99, "Split range at 100")
    }

    static func checkDeterminism(_ c: LogicChecker) {
        func sample(seed: UInt64) -> [Int] {
            var generator = SeededGenerator(seed: seed)
            var values: [Int] = []
            for level in LearningLevel.allCases {
                let build = BuildPuzzle.make(level: level, using: &generator)
                values.append(build.target)
                values.append(contentsOf: build.pieces.map(\.value))
                let pair = PairPuzzle.make(level: level, using: &generator)
                values.append(contentsOf: [pair.target, pair.given] + pair.choices)
                let split = SplitPuzzle.make(level: level, using: &generator)
                values.append(contentsOf: [split.total, split.wantedLeft])
            }
            return values
        }
        c.equal(sample(seed: 99), sample(seed: 99), "Same seed must reproduce the same puzzles")
        c.check(sample(seed: 99) != sample(seed: 100), "Different seeds should normally differ")
    }

    // MARK: Workshop rules

    static func checkWorkshopRules(_ c: LogicChecker) {
        for maximum in maximums {
            for first in 1..<maximum {
                for second in 1...(maximum - first) {
                    c.check(WorkshopRules.isValid(first: first, second: second, maximum: maximum),
                            "\(first)+\(second) must be valid at \(maximum)")
                    c.equal(WorkshopRules.canIncrease(first: first, second: second, maximum: maximum),
                            first + second < maximum, "canIncrease \(first)+\(second) at \(maximum)")
                }
            }
            c.check(WorkshopRules.isValid(first: maximum - 1, second: 1, maximum: maximum), "\(maximum - 1)+1 valid")
            c.check(!WorkshopRules.canIncrease(first: maximum - 1, second: 1, maximum: maximum), "+ disabled at \(maximum)")
            c.check(!WorkshopRules.isValid(first: maximum, second: 1, maximum: maximum), "\(maximum)+1 invalid")
            c.check(!WorkshopRules.isValid(first: 0, second: 1, maximum: maximum), "zero operand invalid")
            c.check(!WorkshopRules.isValid(first: 1, second: 0, maximum: maximum), "zero operand invalid")
            c.check(!WorkshopRules.canDecrease(1), "cannot go below 1")
            c.check(WorkshopRules.canDecrease(2), "2 can decrease")
        }
        c.check(WorkshopRules.isValid(first: 39, second: 1, maximum: 40), "39 + 1 = 40 allowed")
        c.check(WorkshopRules.isValid(first: 20, second: 20, maximum: 40), "20 + 20 = 40 allowed")
        c.check(!WorkshopRules.isValid(first: 39, second: 2, maximum: 40), "39 + 2 = 41 disallowed")
        c.check(WorkshopRules.isValid(first: 99, second: 1, maximum: 100), "99 + 1 = 100 allowed")
        c.check(!WorkshopRules.isValid(first: 99, second: 2, maximum: 100), "99 + 2 = 101 disallowed")
        c.equal(WorkshopSession(level: .hundred).dotColumns, 10, "Workshop frames use rows of ten at 100")
    }

    // MARK: Sessions

    static func checkBuildSession(_ c: LogicChecker) {
        // Forced puzzle for 40 with the spec's example pair.
        let pieces = [18, 22, 5, 5, 30].map(NumberPiece.init)
        var session = BuildSession(puzzle: BuildPuzzle(target: 40, solution: (18, 22), pieces: pieces))
        c.equal(session.currentTotal, 0, "Empty start")
        c.equal(session.availablePieces.count, 5, "All pieces available")
        c.equal(session.hint, "Prøv 18 og 22.", "Hint before any selection")

        c.equal(session.choose(pieces[0]), .progress, "Choosing 18")
        c.equal(session.feedback, "Du har 18. Du trenger 22 til.", "Progress feedback")
        c.equal(session.choose(pieces[0]), .ignored, "Choosing the same piece twice")
        c.equal(session.choose(pieces[4]), .rejected, "30 would overshoot")
        c.equal(session.currentTotal, 18, "Rejected piece must not change the total")
        c.equal(session.selected.count, 1, "Rejected piece must not be selected")
        c.equal(session.feedback, GameCopy.buildTooMany, "Overshoot feedback")
        c.equal(session.availablePieces.count, 4, "One piece used")
        c.equal(session.hint, "Du trenger 22 til. Prøv brikken 22.", "Hint completes the selection")

        c.equal(session.choose(pieces[1]), .solved, "18 + 22 solves 40")
        c.check(session.isSolved, "Solved flag")
        c.equal(session.feedback, "18 pluss 22 er 40. Bra jobbet!", "Solved feedback reflects the actual pieces")
        c.equal(session.hint, "18 pluss 22 er 40. Bra jobbet!", "Hint after completion restates the solution")
        c.check(!session.hint.contains("Ingen brikke passer"), "Hint must not call a solved puzzle stuck")
        c.equal(session.choose(pieces[2]), .ignored, "Locked after completion")
        c.check(!session.remove(pieces[0]), "Cannot remove after completion")
        session.clearSelection()
        c.equal(session.selected.count, 2, "Clear is ignored after completion")
        c.check(session.canStillComplete, "Solved session counts as completable")

        // Any valid composition is accepted, not only the generated pair.
        let alternative = [10, 30, 15, 15, 10].map(NumberPiece.init)
        var free = BuildSession(puzzle: BuildPuzzle(target: 40, solution: (10, 30), pieces: alternative))
        c.equal(free.choose(alternative[2]), .progress, "15")
        c.equal(free.choose(alternative[3]), .progress, "15 + 15")
        c.equal(free.choose(alternative[4]), .solved, "15 + 15 + 10 = 40")
        c.equal(free.feedback, "15 pluss 15 pluss 10 er 40. Bra jobbet!", "Three-piece feedback")

        // Piece identity: removing one 5 must not remove the other 5.
        let twins = [5, 5, 3, 2, 1].map(NumberPiece.init)
        var twinSession = BuildSession(puzzle: BuildPuzzle(target: 10, solution: (5, 5), pieces: twins))
        c.equal(twinSession.choose(twins[0]), .progress, "First 5")
        c.check(!twinSession.remove(twins[1]), "Removing the unselected twin does nothing")
        c.equal(twinSession.currentTotal, 5, "Total unchanged after no-op removal")
        c.check(twinSession.remove(twins[0]), "Removing the selected twin")
        c.equal(twinSession.currentTotal, 0, "Total back to zero")
        c.equal(twinSession.feedback, nil, "Feedback cleared when nothing is selected")
        c.equal(twinSession.choose(twins[0]), .progress, "5 again")
        c.equal(twinSession.choose(twins[1]), .solved, "5 + 5 = 10 using both twins")

        // Stuck detection and honest hints.
        let stuckPieces = [9, 8, 7, 1, 6].map(NumberPiece.init)
        var stuck = BuildSession(puzzle: BuildPuzzle(target: 10, solution: (9, 1), pieces: stuckPieces))
        c.equal(stuck.choose(stuckPieces[1]), .progress, "8")
        c.check(!stuck.canStillComplete, "No remaining piece makes 2")
        c.check(stuck.feedback?.contains("Ingen brikke passer nå") == true, "Stuck feedback explains the problem")
        c.equal(stuck.choose(stuckPieces[0]), .rejected, "9 overshoots while stuck")
        c.equal(stuck.feedback, GameCopy.buildTooMany(stuck: true), "Overshoot while stuck keeps the take-a-piece-back guidance")
        c.check(stuck.feedback?.contains("Ta bort en brikke") == true, "Stuck overshoot feedback is followable")
        c.equal(stuck.currentTotal, 8, "Rejected piece changes nothing")
        c.equal(stuck.hint, GameCopy.buildHintStuck(9, 1), "Stuck hint suggests removing a piece")
        stuck.showHint()
        c.equal(stuck.feedback, stuck.hint, "showHint publishes the hint")
        c.check(stuck.remove(stuckPieces[1]), "Remove the 8")
        c.equal(stuck.hint, "Prøv 9 og 1.", "Hint returns to the pair")
        stuck.clearSelection()
        c.equal(stuck.selected.count, 0, "Clear selection")

        // Multi-piece completion hint, fewest pieces first.
        let hintPieces = [3, 7, 4, 2, 1].map(NumberPiece.init)
        var hinted = BuildSession(puzzle: BuildPuzzle(target: 10, solution: (3, 7), pieces: hintPieces))
        hinted.choose(hintPieces[0])
        c.equal(hinted.hint, "Du trenger 7 til. Prøv brikken 7.", "Single-piece completion")
        hinted.choose(hintPieces[2])
        c.equal(hinted.hint, "Prøv brikkene 2 og 1.", "Two-piece completion")

        // Random play: the generated pair always solves, exactly once, at every level.
        var generator = SeededGenerator(seed: 77)
        for level in LearningLevel.allCases {
            for _ in 0..<2_000 {
                let puzzle = BuildPuzzle.make(level: level, using: &generator)
                var play = BuildSession(puzzle: puzzle)
                // Report (never trap) if the generator ever stops offering its own pair.
                guard let first = puzzle.pieces.first(where: { $0.value == puzzle.solution.0 }),
                      let second = puzzle.pieces.first(where: { $0.value == puzzle.solution.1 && $0.id != first.id })
                else {
                    c.check(false, "Generated pair \(puzzle.solution) missing from pieces for target \(puzzle.target)")
                    continue
                }
                let outcomes = [play.choose(first), play.choose(second)]
                c.equal(outcomes, [.progress, .solved], "Generated pair solves \(puzzle.target)")
                c.equal(play.currentTotal, puzzle.target, "Solved total equals target")
                c.equal(play.choose(puzzle.pieces[0]), .ignored, "No further changes once solved")

                // Greedy play never overshoots and never gets a total above the target.
                var greedy = BuildSession(puzzle: puzzle)
                var solvedCount = 0
                for piece in puzzle.pieces {
                    let before = greedy.currentTotal
                    let outcome = greedy.choose(piece)
                    if outcome == .solved { solvedCount += 1 }
                    if outcome == .rejected {
                        c.equal(greedy.currentTotal, before, "Rejected pieces leave the total alone")
                    }
                    c.check(greedy.currentTotal <= puzzle.target, "Total never exceeds target")
                }
                c.check(solvedCount <= 1, "Solved at most once")
                c.equal(greedy.isSolved, solvedCount == 1, "Solved flag matches outcome")
            }
        }
    }

    static func checkPairSession(_ c: LogicChecker) {
        let puzzle = PairPuzzle(target: 40, given: 18, answer: 22, choices: [22, 7, 18, 39])
        var session = PairSession(puzzle: puzzle)
        c.equal(session.answer(7), .incorrect, "7 is wrong")
        c.equal(session.feedback,
                "Prøv igjen. 18 pluss 7 er 25. Det er for lite. Tell hvor mange som mangler til 40.",
                "Wrong answer feedback shows the real sum and direction")
        c.check(!session.isSolved, "Still active after a wrong answer")
        c.equal(session.answer(39), .incorrect, "39 is wrong")
        c.check(session.feedback?.contains("18 pluss 39 er 57. Det er for mye.") == true, "Too-much feedback")
        c.equal(session.wrongAttempts, 2, "Two wrong attempts")
        c.equal(session.triedChoices, [7, 39], "Tried choices remembered")
        c.equal(session.answer(100), .ignored, "Values that are not choices are ignored")
        c.equal(session.answer(22), .solved, "22 completes 18 + 22 = 40")
        c.equal(session.feedback, "Riktig! 18 pluss 22 er 40.", "Solved feedback")
        c.equal(session.answer(7), .ignored, "Locked after solving")
        c.equal(session.answer(22), .ignored, "Solving twice is impossible")

        var generator = SeededGenerator(seed: 1234)
        for level in LearningLevel.allCases {
            for _ in 0..<2_000 {
                let random = PairPuzzle.make(level: level, using: &generator)
                var play = PairSession(puzzle: random)
                for wrong in random.choices where wrong != random.answer {
                    c.equal(play.answer(wrong), .incorrect, "Wrong choice stays active")
                    c.check(!play.isSolved, "Not solved by a wrong choice")
                }
                c.equal(play.wrongAttempts, 3, "Three distractors tried")
                c.equal(play.answer(random.answer), .solved, "Correct choice solves")
                c.equal(play.answer(random.answer), .ignored, "Solved only once")
            }
        }
    }

    static func checkSplitSession(_ c: LogicChecker) {
        var session = SplitSession(puzzle: SplitPuzzle(total: 40, wantedLeft: 17))
        c.equal(session.left, 20, "Starts in the middle")
        c.equal(session.right, 20, "Right follows left")
        session.setLeft(0)
        c.equal(session.left, 1, "Left is clamped to at least 1")
        c.equal(session.right, 39, "Right stays positive")
        session.decrease()
        c.equal(session.left, 1, "Cannot go below 1")
        c.check(!session.canDecrease, "Decrease disabled at 1")
        session.setLeft(45)
        c.equal(session.left, 39, "Left is clamped to total - 1")
        session.increase()
        c.equal(session.left, 39, "Cannot exceed total - 1")
        c.check(!session.canIncrease, "Increase disabled at 39")
        session.setLeft(20)
        c.equal(session.check(), .incorrect, "20 is not 17")
        c.equal(session.feedback, "Du har 20 til venstre. Du trenger færre prikker til venstre.", "Points down")
        session.setLeft(10)
        c.equal(session.check(), .incorrect, "10 is not 17")
        c.equal(session.feedback, "Du har 10 til venstre. Du trenger flere prikker til venstre.", "Points up")
        session.setLeft(17)
        c.equal(session.check(), .solved, "17 + 23 = 40")
        c.equal(session.feedback, "Kjempebra! 40 er 17 og 23 sammen.", "Solved feedback")
        session.setLeft(5)
        c.equal(session.left, 17, "Locked after solving")
        session.increase()
        c.equal(session.left, 17, "Buttons locked after solving")
        c.equal(session.check(), .ignored, "Cannot solve twice")

        c.equal(SplitPuzzle(total: 5, wantedLeft: 2).startingLeft, 3, "Avoids starting on the answer")
        c.equal(SplitPuzzle(total: 5, wantedLeft: 3).startingLeft, 2, "Avoids starting on the answer")
        c.equal(SplitPuzzle(total: 40, wantedLeft: 20).startingLeft, 21, "Avoids starting on the answer at 40")

        var generator = SeededGenerator(seed: 555)
        for level in LearningLevel.allCases {
            for _ in 0..<2_000 {
                let puzzle = SplitPuzzle.make(level: level, using: &generator)
                var play = SplitSession(puzzle: puzzle)
                c.check(play.left != play.wantedLeft, "Never starts solved")
                for value in play.leftRange {
                    play.setLeft(value)
                    c.equal(play.left + play.right, puzzle.total, "Groups always add up to \(puzzle.total)")
                    c.check(play.left >= 1 && play.right >= 1, "Groups never empty")
                }
                play.setLeft(puzzle.wantedLeft)
                c.equal(play.check(), .solved, "Correct split solves")
                c.equal(play.check(), .ignored, "Solved once")
            }
        }
    }

    static func checkWorkshopSession(_ c: LogicChecker) {
        var session = WorkshopSession(maximum: 40)
        c.equal(session.first, 3, "Default first")
        c.equal(session.second, 4, "Default second")
        for _ in 0..<33 { session.increaseFirst() }
        c.equal(session.total, 40, "36 + 4 = 40")
        c.check(!session.canIncrease, "+ disabled at 40")
        session.increaseSecond()
        c.equal(session.total, 40, "Cannot reach 41")
        for _ in 0..<3 { session.decreaseSecond() }
        c.equal(session.second, 1, "Second down to 1")
        session.decreaseSecond()
        c.equal(session.second, 1, "Never below 1")
        c.check(!session.canDecreaseSecond, "- disabled at 1")
        for _ in 0..<3 { session.increaseFirst() }
        c.equal(session.equation, "39 + 1 = 40", "39 + 1 = 40 is reachable")
        c.equal(session.spokenEquation, "39 pluss 1 er 40.", "Spoken equation")
        c.check(!session.canIncrease, "39 + 2 = 41 is impossible")
        session.increaseFirst()
        c.equal(session.first, 39, "First stays at 39")

        var even = WorkshopSession(level: .advanced)
        for _ in 0..<17 { even.increaseFirst() }
        for _ in 0..<16 { even.increaseSecond() }
        c.equal(even.equation, "20 + 20 = 40", "20 + 20 = 40 is reachable")
        c.check(!even.canIncrease, "+ disabled at 20 + 20")

        even.updateMaximum(10)
        c.check(even.isValid, "Still valid after lowering the level")
        c.equal(even.total, 10, "Shrinks to the new maximum")
        c.check(even.first >= 1 && even.second >= 1, "Operands stay positive after clamping")
        session.updateMaximum(10)
        c.equal(session.equation, "9 + 1 = 10", "39 + 1 clamps to 9 + 1")

        for maximum in maximums {
            var play = WorkshopSession(maximum: maximum)
            c.check(play.isValid, "Default values valid at \(maximum)")
            var steps = 0
            while play.canIncrease, steps < 100 {
                play.increaseFirst()
                steps += 1
            }
            c.equal(play.total, maximum, "Increments reach exactly \(maximum)")
            c.check(!play.canIncrease, "No increment past \(maximum)")
            c.check(play.total <= maximum, "Never above \(maximum)")
            while play.canDecreaseFirst { play.decreaseFirst() }
            c.equal(play.first, 1, "First never below 1")
        }
    }

    static func checkCopy(_ c: LogicChecker) {
        c.equal(GameCopy.dots(1), "1 prikk", "Singular dot")
        c.equal(GameCopy.dots(40), "40 prikker", "Plural dots")
        c.equal(GameCopy.tasksSolved(1), "1 oppgave løst", "Singular task")
        c.equal(GameCopy.tasksSolved(12), "12 oppgaver løst", "Plural tasks")
        c.equal(GameCopy.list([3]), "3", "List of one")
        c.equal(GameCopy.list([3, 4]), "3 og 4", "List of two")
        c.equal(GameCopy.list([3, 4, 5]), "3, 4 og 5", "List of three")
        c.equal(GameCopy.plusChain([18, 22]), "18 pluss 22", "Plus chain")
        c.equal(GameCopy.splitWanted(1), "Lag 1 prikk til venstre.", "Singular split instruction")
        c.equal(GameCopy.splitTotal(40), "Du har 40 prikker.", "Split total")
        c.equal(GameCopy.workshopInstruction(maximum: 40),
                "Trykk på pluss og minus for å endre tallene. Du kan velge tall fra 1 til 39 og lage summer opp til 40.",
                "Workshop instruction")
        c.equal(GameCopy.buildTooMany(stuck: false), GameCopy.buildTooMany, "Plain overshoot copy")
        c.equal(GameCopy.buildPrompt(target: 40), "Kan du lage 40?", "Build prompt")
        c.equal(GameCopy.pairPrompt(given: 18, target: 40), "18 pluss hvilket tall er 40?", "Pair prompt")
        c.equal(GameCopy.splitPrompt(total: 40, wantedLeft: 17), "Du har 40 prikker. Lag 17 prikker til venstre.", "Split prompt")
        c.equal(GameCopy.splitPrompt(total: 5, wantedLeft: 1), "Du har 5 prikker. Lag 1 prikk til venstre.", "Split prompt singular")
        c.equal(GameCopy.workshopPrompt, "Trykk på pluss og minus for å endre tallene.", "Workshop prompt")
        c.equal(GameCopy.homeMenuIntro, "Velg en lek.", "Home menu intro")
        c.equal(GameCopy.levelChooserIntro, "Hvor store tall vil du leke med?", "Chooser intro")
        c.equal(LearningLevel.starterChoices.map(GameCopy.levelChoice), ["Til 20", "Til 40", "Til 100"], "Chooser choices")
        c.equal(BuildSession(level: .hundred).level, .hundred, "Build session remembers its level")
        c.equal(PairSession(level: .hundred).level.dotColumns, 10, "Pair session level columns")
        c.equal(SplitSession(level: .start).level.dotColumns, 5, "Split session level columns")
        let spokenPair = PairSession(puzzle: PairPuzzle(target: 40, given: 18, answer: 22, choices: [22, 7, 18, 39]))
        c.equal(spokenPair.prompt, "18 pluss hvilket tall er 40?", "Pair session prompt")
        c.equal(spokenPair.spokenEquation, "18 pluss hvilket tall er 40", "Unsolved spoken equation")
        var spokenSolved = spokenPair
        spokenSolved.answer(22)
        c.equal(spokenSolved.spokenEquation, "18 pluss 22 er 40", "Solved spoken equation")
        let spokenSplit = SplitSession(puzzle: SplitPuzzle(total: 40, wantedLeft: 17))
        c.equal(spokenSplit.prompt, "Du har 40 prikker. Lag 17 prikker til venstre.", "Split session prompt")
        c.equal(spokenSplit.spokenState, "20 til venstre og 20 til høyre", "Split spoken state")
        let spokenBuild = BuildSession(puzzle: BuildPuzzle(target: 40, solution: (18, 22), pieces: [18, 22, 5, 5, 30].map(NumberPiece.init)))
        c.equal(spokenBuild.prompt, "Kan du lage 40?", "Build session prompt")
    }

    static func checkCompletionSearch(_ c: LogicChecker) {
        let pieces = [4, 6, 10, 2, 2].map(NumberPiece.init)
        c.equal(BuildPuzzle.completion(for: 10, from: pieces)?.map(\.value), [10], "Prefers a single piece")
        c.equal(BuildPuzzle.completion(for: 8, from: pieces)?.map(\.value), [6, 2], "Finds a pair")
        c.equal(BuildPuzzle.completion(for: 14, from: pieces)?.map(\.value), [4, 10], "Finds 4 + 10")
        c.equal(BuildPuzzle.completion(for: 24, from: pieces)?.map(\.value), [4, 6, 10, 2, 2], "Uses all pieces")
        c.equal(BuildPuzzle.completion(for: 25, from: pieces)?.map(\.value), nil, "Impossible amount")
        c.equal(BuildPuzzle.completion(for: 0, from: pieces)?.map(\.value), nil, "Zero needs nothing")
        c.equal(BuildPuzzle.completion(for: 3, from: [])?.map(\.value), nil, "No pieces")
    }

    // MARK: Tallstolper

    static let barBuildMaximums = [5, 10, 20]
    static let barSplitMaximums = [6, 10]

    static func checkBarPuzzle(_ c: LogicChecker, _ puzzle: BarPuzzle, maximum: Int) {
        c.check(puzzle.bars.allSatisfy { BarRules.isValidBar($0.value) }, "Every bar holds 1 to 10 units")
        c.equal(Set(puzzle.bars.map(\.id)).count, puzzle.bars.count, "Bar identities are distinct")
        switch puzzle.mode {
        case .build:
            let range = BarPuzzle.buildTargetRange(maximum: maximum)
            c.check(range.contains(puzzle.target), "Bar target \(puzzle.target) outside \(range) for maximum \(maximum)")
            c.check(puzzle.bars.allSatisfy { $0.value < puzzle.target }, "Shelf bars stay below the target \(puzzle.target)")
            c.check(puzzle.parts.count == 2 || puzzle.parts.count == 3, "Two or three parts")
            c.check(puzzle.parts.allSatisfy { BarRules.isValidBar($0) }, "Parts fit one bar each")
            c.equal(puzzle.parts.reduce(0, +), puzzle.target, "Parts add up to the target")
            c.equal(puzzle.bars.count, puzzle.parts.count + 2, "Two extra bars on the shelf")
            var remainingValues = puzzle.bars.map(\.value)
            var allPartsOffered = true
            for part in puzzle.parts {
                if let index = remainingValues.firstIndex(of: part) {
                    remainingValues.remove(at: index)
                } else {
                    allPartsOffered = false
                }
            }
            c.check(allPartsOffered, "The shelf offers every part of \(puzzle.parts)")
            c.check(BuildPuzzle.completion(for: puzzle.target, from: puzzle.bars) != nil, "Build task \(puzzle.target) is solvable by placing whole bars")
        case .split:
            let range = BarPuzzle.splitTotalRange(maximum: maximum)
            c.check(range.contains(puzzle.target), "Split total \(puzzle.target) outside \(range) for maximum \(maximum)")
            c.equal(puzzle.parts.count, 2, "Two wanted parts")
            c.check(puzzle.parts.allSatisfy { $0 >= 1 }, "Wanted parts are positive")
            c.equal(puzzle.parts.reduce(0, +), puzzle.target, "Wanted parts add up to the bar")
            c.equal(puzzle.bars.map(\.value), [puzzle.target], "One bar to cut")
        }
    }

    static func checkBarRules(_ c: LogicChecker) {
        c.equal(BarRules.maximumBarValue, 10, "Bars hold at most ten units")
        for value in 1...10 {
            c.check(BarRules.isValidBar(value), "\(value) is a bar")
            for other in 1...10 {
                c.equal(BarRules.canCombine(value, other), value + other <= 10, "Combine \(value)+\(other)")
            }
            for bottom in 0...11 {
                c.equal(BarRules.canSplit(value, bottom: bottom), bottom >= 1 && bottom < value, "Split \(value) at \(bottom)")
            }
        }
        for invalid in [Int.min, -1, 0, 11, 100, Int.max] {
            c.check(!BarRules.isValidBar(invalid), "\(invalid) is not a bar")
        }
        c.check(!BarRules.canCombine(0, 5), "Zero never combines")
        c.equal(BarRules.rods(in: 14), 1, "14 holds one tens rod")
        c.equal(BarRules.units(in: 14), 4, "14 leaves four units")
        c.equal(BarRules.rods(in: 20), 2, "20 holds two rods")
        c.equal(BarRules.units(in: 20), 0, "20 leaves no unit")
        c.equal(BarRules.rods(in: 0), 0, "Empty zone has no rod")
        c.equal(BarRules.rods(in: -3), 0, "Negative totals are treated as empty")
        c.equal(BarPuzzle.buildTargetRange(maximum: 5), 2...5, "Build range to 5")
        c.equal(BarPuzzle.buildTargetRange(maximum: 10), 2...10, "Build range to 10")
        c.equal(BarPuzzle.buildTargetRange(maximum: 20), 11...20, "Build range to 20 always needs a rod")
        c.equal(BarPuzzle.splitTotalRange(maximum: 6), 2...6, "Split range to 6")
        c.equal(BarPuzzle.splitTotalRange(maximum: 10), 2...10, "Split range to 10")
        c.equal(BarPuzzle.splitTotalRange(maximum: 20), 2...10, "A split bar never exceeds ten")
        let opacities = [5, 6, 10, 11, 19, 20, 40, 100].map(BarRules.numeralOpacity(forMaximum:))
        c.equal(opacities, [0, 0.55, 0.55, 0.8, 0.8, 1, 1, 1], "Numeral opacity table: hidden to 5, 0.55 to 10, 0.8 to 19, opaque from 20")
        c.equal(BarRules.numeralOpacity(forMaximum: 0), 0, "Degenerate range hides the numeral")
        c.check(zip(opacities, opacities.dropFirst()).allSatisfy { $0 <= $1 }, "Numeral opacity never decreases with the range")
        c.check(opacities.allSatisfy { (0...1).contains($0) }, "Opacities stay in 0…1")

        // The searches behind the build hints.
        c.equal(BarRules.fewestBars(adding: 10, from: [6, 4, 7, 2, 2]), [6, 4], "Fewest bars for 10")
        c.equal(BarRules.fewestBars(adding: 6, from: [4, 3, 3, 2]), [4, 2], "Ties go to the larger bars")
        c.equal(BarRules.fewestBars(adding: 4, from: [2, 1, 2, 1]), [2, 2], "Two twos before two twos and ones")
        c.equal(BarRules.fewestBars(adding: 19, from: [1, 10, 1, 9, 1]), [10, 9], "Two bars beat ones")
        c.equal(BarRules.fewestBars(adding: 3, from: [2, 2, 2]), nil, "No subset of twos makes 3")
        c.equal(BarRules.fewestBars(adding: 0, from: [1]), nil, "Nothing is needed for 0")
        c.equal(BarRules.fewestBars(adding: 5, from: []), nil, "An empty shelf completes nothing")
        c.equal(BarRules.fewestBars(adding: 20, from: Array(repeating: 1, count: 40)), Array(repeating: 1, count: 20), "Forty ones stay instant")
        func cut(_ amount: Int, _ values: [Int]) -> [Int]? {
            BarRules.cutToComplete(amount, from: values).map { [$0.value, $0.bottom] }
        }
        c.equal(cut(2, [9, 3]), [3, 2], "Cut the smaller bar that is tall enough")
        c.equal(cut(5, [3, 3, 3]), [3, 2], "Cut a 3 so that 3 + 2 completes 5")
        c.equal(cut(3, [2, 2, 2]), [2, 1], "Cut a 2 so that 2 + 1 completes 3")
        c.equal(cut(1, [6, 3, 2]), [2, 1], "A 1 comes from the smallest bar")
        c.equal(cut(4, [1, 1]), nil, "Ones cannot be cut")
        c.equal(cut(0, [5]), nil, "Nothing to cut for 0")
        c.equal(cut(12, [9, 4, 2, 2]), [4, 3], "Fewest bars beat the smallest bar: 4 into 3 and 1, then 9 + 3")
        c.equal(cut(10, [7, 6, 5]), [5, 4], "Ties keep the larger lower part")
    }

    static func checkRandomizedBars(_ c: LogicChecker, rounds: Int, seed: UInt64) {
        for maximum in barBuildMaximums {
            var generator = SeededGenerator(seed: seed &+ UInt64(maximum))
            var seenTop = false
            for _ in 0..<rounds {
                let puzzle = BarPuzzle.makeBuild(maximum: maximum, using: &generator)
                checkBarPuzzle(c, puzzle, maximum: maximum)
                if puzzle.target == maximum { seenTop = true }
            }
            if rounds >= 1_000 {
                c.check(seenTop, "Random bar building at \(maximum) reaches \(maximum) within \(rounds) rounds")
            }
        }
        for maximum in barSplitMaximums {
            var generator = SeededGenerator(seed: seed &+ 1_000 &+ UInt64(maximum))
            for _ in 0..<rounds {
                checkBarPuzzle(c, BarPuzzle.makeSplit(maximum: maximum, using: &generator), maximum: maximum)
            }
        }
        for maximum in barBuildMaximums {
            for target in BarPuzzle.buildTargetRange(maximum: maximum) {
                var generator = SeededGenerator(seed: 777 &+ UInt64(target))
                for _ in 0..<5 {
                    checkBarPuzzle(c, BarPuzzle.makeBuild(maximum: maximum, target: target, using: &generator), maximum: maximum)
                }
            }
        }
        for maximum in barSplitMaximums {
            for total in BarPuzzle.splitTotalRange(maximum: maximum) {
                var generator = SeededGenerator(seed: 888 &+ UInt64(total))
                checkBarPuzzle(c, BarPuzzle.makeSplit(maximum: maximum, total: total, using: &generator), maximum: maximum)
            }
        }
        for _ in 0..<20 {
            checkBarPuzzle(c, BarPuzzle.makeBuild(maximum: 10), maximum: 10)
            checkBarPuzzle(c, BarPuzzle.makeSplit(maximum: 10), maximum: 10)
        }
        func sample(seed: UInt64) -> [Int] {
            var generator = SeededGenerator(seed: seed)
            let build = BarPuzzle.makeBuild(maximum: 20, using: &generator)
            let split = BarPuzzle.makeSplit(maximum: 10, using: &generator)
            return [build.target] + build.bars.map(\.value) + [split.target] + split.parts
        }
        c.equal(sample(seed: 5), sample(seed: 5), "Seeded bar puzzles are reproducible")
    }

    static func checkBarSession(_ c: LogicChecker) {
        // Build 10 from a shelf of 6, 4, 7, 2, 2.
        let bars = [6, 4, 7, 2, 2].map(NumberPiece.init)
        var session = BarSession(puzzle: BarPuzzle(mode: .build, target: 10, parts: [6, 4], bars: bars))
        c.check(!session.hasStarted, "Nothing has happened yet")
        c.equal(session.prompt, "Bygg 10 med stolpene.", "Build prompt")
        c.equal(session.hint, "Prøv 6 og 4.", "Hint names the partition before anything moved")
        c.equal(session.combine(bars[3].id, onto: bars[4].id), .progress, "2 onto 2 combines")
        c.equal(session.feedback, "2 og 2 ble 4.", "Combine feedback")
        c.equal(session.shelf.map(\.value), [6, 4, 7, 4], "Combined bar takes the drop target's place")
        c.check(session.lastCombined == session.shelf[3].id, "Last combined bar is reported")
        c.check(session.hasStarted, "A combine counts as a start")
        c.equal(session.combine(bars[2].id, onto: bars[0].id), .rejected, "7 onto 6 would pass ten")
        c.equal(session.feedback, GameCopy.barOverTen, "Over-ten feedback")
        c.equal(session.shelf.map(\.value), [6, 4, 7, 4], "Rejected combine changes nothing")
        c.equal(session.place(bars[0].id), .progress, "Place 6")
        c.equal(session.feedback, "Du har 6. Du trenger 4 til.", "Progress feedback")
        c.equal(session.remaining, 4, "Remaining after 6")
        c.equal(session.place(bars[2].id), .rejected, "7 would pass the target")
        c.equal(session.feedback, GameCopy.barTooTall, "Too tall feedback")
        c.equal(session.placedTotal, 6, "Rejected bar is not placed")
        c.equal(session.shelf.count, 3, "Rejected bar stays on the shelf")
        c.equal(session.combine(bars[2].id, onto: bars[1].id), .rejected, "7 onto 4 would pass ten")
        c.equal(session.feedback, GameCopy.barOverTen, "Above ten is refused first")
        let fours = session.shelf.filter { $0.value == 4 }
        c.equal(session.combine(fours[0].id, onto: fours[1].id), .rejected, "4 onto 4 fits one bar but passes the remaining 4")
        c.equal(session.feedback, GameCopy.barTooTall, "Too-tall combine feedback")
        c.equal(session.shelf.map(\.value), [4, 7, 4], "Refused combines change nothing")
        c.equal(session.hint, "Du trenger 4 til. Prøv stolpen 4.", "Hint completes the zone")
        c.equal(session.takeBackLast(), .progress, "Take the 6 back")
        c.equal(session.placedTotal, 0, "Zone empty again")
        c.equal(session.feedback, nil, "No feedback with an empty zone")
        c.equal(session.shelf.map(\.value), [4, 7, 4, 6], "Taken-back bar returns to the end of the shelf")
        c.equal(session.takeBackLast(), .ignored, "Nothing left to take back")
        c.equal(session.split(bars[2].id, bottom: 3), .progress, "Cut 7 into 3 and 4")
        c.equal(session.feedback, "7 ble 3 og 4.", "Split feedback")
        c.equal(session.shelf.map(\.value), [4, 3, 4, 4, 6], "Cut parts stay where the bar was")
        c.equal(session.lastSplit.count, 2, "Both new bars are reported")
        c.check(session.lastSplit == [session.shelf[1].id, session.shelf[2].id], "Reported bars are the two parts")
        c.equal(session.split(session.shelf[1].id, bottom: 3), .rejected, "A cut must leave two parts")
        c.equal(session.split(session.shelf[1].id, bottom: 0), .rejected, "A cut needs a positive bottom")
        c.equal(session.split(UUID(), bottom: 1), .ignored, "Unknown bars are ignored")
        c.equal(session.shelf.count, 5, "Refused cuts change nothing")
        c.equal(session.place(session.shelf[4].id), .progress, "Place 6 again")
        let four = session.shelf[0]
        c.equal(session.place(four.id), .solved, "6 + 4 solves 10")
        c.check(session.isSolved, "Solved flag")
        c.equal(session.feedback, "6 pluss 4 er 10. Bra bygget!", "Solved feedback lists the placed bars")
        c.equal(session.rods, 1, "Ten is one rod")
        c.equal(session.units, 0, "Ten leaves no unit")
        c.equal(session.hint, "6 pluss 4 er 10. Bra bygget!", "Hint after completion restates the result")
        c.equal(session.place(session.shelf[0].id), .ignored, "Locked after completion")
        c.equal(session.takeBackLast(), .ignored, "Locked take-back")
        c.equal(session.combine(session.shelf[0].id, onto: session.shelf[1].id), .ignored, "Locked combine")
        c.equal(session.split(session.shelf[0].id, bottom: 1), .ignored, "Locked split")
        c.equal(session.shelf.count, 3, "Shelf unchanged after completion")

        // Hint suggests a cut when only a taller bar is left.
        let tallBars = [9, 8, 3].map(NumberPiece.init)
        var tall = BarSession(puzzle: BarPuzzle(mode: .build, target: 10, parts: [8, 2], bars: tallBars))
        c.equal(tall.place(tallBars[1].id), .progress, "Place 8")
        c.equal(tall.hint, "Del stolpen 3 i 2 og 1.", "Hint proposes the cut of the smaller bar that is tall enough")
        tall.showHint()
        c.equal(tall.feedback, tall.hint, "showHint publishes the hint")
        c.equal(tall.split(tallBars[2].id, bottom: 2), .progress, "Cut as hinted")
        c.equal(tall.hint, "Du trenger 2 til. Prøv stolpen 2.", "After the cut the hint names the part")
        c.equal(tall.place(tall.shelf.first { $0.value == 2 }!.id), .solved, "The 2 completes 10")

        // Tens rods: a target above ten.
        let teenBars = [8, 6, 5, 3, 2].map(NumberPiece.init)
        var teen = BarSession(puzzle: BarPuzzle(mode: .build, target: 14, parts: [8, 6], bars: teenBars))
        c.equal(teen.place(teenBars[0].id), .progress, "Place 8 of 14")
        c.equal(teen.place(teenBars[2].id), .progress, "Place 5 of 14")
        c.equal(teen.rods, 1, "13 shows one rod")
        c.equal(teen.units, 3, "13 shows three units")
        c.equal(teen.place(teenBars[2].id), .ignored, "A placed bar cannot be placed twice")
        c.equal(teen.place(teenBars[1].id), .rejected, "6 would make 19")
        c.equal(teen.hint, "Del stolpen 2 i 1 og 1.", "Hint proposes a cut when no bar fits")
        c.equal(teen.split(teenBars[4].id, bottom: 1), .progress, "Cut 2 into 1 and 1")
        c.equal(teen.place(teen.shelf.first { $0.value == 1 }!.id), .solved, "14 built")
        c.equal(teen.rods, 1, "14 is one rod")
        c.equal(teen.units, 4, "14 leaves four units")

        // Hints never name bars that have left the shelf.
        let staleBars = [3, 3, 2, 3, 1].map(NumberPiece.init)
        var stale = BarSession(puzzle: BarPuzzle(mode: .build, target: 8, parts: [3, 3, 2], bars: staleBars))
        c.equal(stale.place(staleBars[2].id), .progress, "Place 2 of 8")
        c.equal(stale.place(staleBars[4].id), .progress, "Place 1 of 8")
        c.equal(stale.shelf.map(\.value), [3, 3, 3], "Only threes are left for the missing 5")
        c.equal(stale.hint, "Del stolpen 3 i 2 og 1.", "No 2 is left, so the hint cuts a 3")
        c.equal(stale.split(staleBars[0].id, bottom: 2), .progress, "Cut as hinted")
        c.equal(stale.hint, "Prøv stolpene 3 og 2.", "Then 3 and 2 complete the zone")
        let leftovers = [3, 3, 4, 1, 1].map(NumberPiece.init)
        var leftover = BarSession(puzzle: BarPuzzle(mode: .build, target: 10, parts: [3, 3, 4], bars: leftovers))
        c.equal(leftover.place(leftovers[2].id), .progress, "Place 4 of 10")
        c.equal(leftover.place(leftovers[3].id), .progress, "Place 1 of 10")
        c.equal(leftover.hint, "Del stolpen 3 i 2 og 1.", "3 + 3 would pass the missing 5: cut a 3")
        c.check(!leftover.hint.contains("4"), "The placed 4 is never named again")
        let mixed = [1, 4, 1, 2].map(NumberPiece.init)
        var remade = BarSession(puzzle: BarPuzzle(mode: .build, target: 5, parts: [1, 4], bars: mixed))
        c.equal(remade.place(mixed[3].id), .progress, "Place 2 of 5")
        c.equal(remade.combine(mixed[0].id, onto: mixed[2].id), .progress, "1 onto 1 fits the missing 3")
        c.equal(remade.split(mixed[1].id, bottom: 2), .progress, "Cut 4 into 2 and 2")
        c.equal(remade.shelf.map(\.value), [2, 2, 2], "Three twos for the missing 3")
        c.equal(remade.hint, "Del stolpen 2 i 1 og 1.", "The hint cuts a 2, it never names the 1 and 4 that are gone")

        // Cutting every bar into ones never breaks the hint, however long the shelf gets.
        let tallShelf = [8, 6, 5, 3, 2].map(NumberPiece.init)
        var ones = BarSession(puzzle: BarPuzzle(mode: .build, target: 14, parts: [8, 6], bars: tallShelf))
        while let bar = ones.shelf.first(where: { $0.value > 1 }) {
            c.equal(ones.split(bar.id, bottom: 1), .progress, "Cut \(bar.value) to a one")
        }
        c.equal(ones.shelf.count, 24, "Twenty-four ones on the shelf")
        c.equal(ones.buildHintStep, .place(Array(repeating: 1, count: 14)), "Hint names fourteen ones")
        c.equal(ones.hint, "Prøv 14 enere.", "Many ones are counted, not listed")
        for _ in 0..<13 {
            c.equal(ones.place(ones.shelf[0].id), .progress, "A one is a step")
        }
        c.equal(ones.place(ones.shelf[0].id), .solved, "Fourteen ones build 14")
        c.equal(GameCopy.barHintPlace([6, 1, 1, 1, 1]), "Prøv stolpen 6 og 4 enere.", "One bar and ones")
        c.equal(GameCopy.barHintPlace([6, 3, 1, 1]), "Prøv stolpene 6 og 3, og så 2 enere.", "Bars and ones in two clauses")
        c.equal(GameCopy.barHintPlace([2, 2, 1, 1]), "Prøv stolpene 2 og 2, og så 2 enere.", "The count of ones is never heard as a bar")
        c.equal(GameCopy.barHintPlace([3, 1]), "Prøv stolpene 3 og 1.", "A single one is listed")

        // Split 8 into 3 and 5.
        let eight = NumberPiece(8)
        var cut = BarSession(puzzle: BarPuzzle(mode: .split, target: 8, parts: [3, 5], bars: [eight]))
        c.equal(cut.prompt, "Del stolpen 8 i 3 og 5.", "Split prompt")
        c.equal(cut.hint, "Del stolpen 8 i 3 og 5. " + GameCopy.barHintSplitGesture, "Split hint explains the gesture")
        c.equal(cut.place(eight.id), .ignored, "Nothing to place in a split task")
        c.equal(cut.split(eight.id, bottom: 2), .incorrect, "2 and 6 is not the wanted cut")
        c.equal(cut.feedback, "Du har 2 og 6. Oppgaven er 3 og 5. Dra stolpene sammen og del på nytt.", "Wrong cut feedback")
        c.check(!cut.isSolved, "Still active after a wrong cut")
        let six = cut.shelf[1]
        c.equal(cut.split(six.id, bottom: 3), .progress, "Cutting again is a step")
        c.equal(cut.shelf.map(\.value), [2, 3, 3], "Three bars now")
        c.equal(cut.combine(cut.shelf[0].id, onto: cut.shelf[1].id), .solved, "2 onto 3 makes 5 and 3: solved")
        c.equal(cut.feedback, "8 er 5 og 3. Kjempebra!", "Solved split feedback names the actual parts")
        c.equal(cut.split(cut.shelf[0].id, bottom: 1), .ignored, "Locked after solving")
        var direct = BarSession(puzzle: BarPuzzle(mode: .split, target: 8, parts: [3, 5], bars: [NumberPiece(8)]))
        c.equal(direct.split(direct.shelf[0].id, bottom: 5), .solved, "5 and 3 also solves 3 and 5")
        c.equal(direct.hint, "8 er 3 og 5. Kjempebra!", "Hint after solving")

        // Random play at every node range.
        var generator = SeededGenerator(seed: 4321)
        for maximum in barBuildMaximums {
            for _ in 0..<500 {
                let puzzle = BarPuzzle.makeBuild(maximum: maximum, using: &generator)
                var play = BarSession(puzzle: puzzle)
                var used: Set<UUID> = []
                var outcomes: [AnswerOutcome] = []
                for part in puzzle.parts {
                    guard let piece = play.shelf.first(where: { $0.value == part && !used.contains($0.id) }) else {
                        c.check(false, "Part \(part) missing on the shelf for \(puzzle.target)")
                        continue
                    }
                    used.insert(piece.id)
                    outcomes.append(play.place(piece.id))
                }
                c.equal(outcomes.last, .solved, "Placing the parts solves \(puzzle.target)")
                c.equal(outcomes.filter { $0 == .solved }.count, 1, "Solved once")
                c.check(outcomes.dropLast().allSatisfy { $0 == .progress }, "Earlier parts are steps")
                c.equal(play.placedTotal, puzzle.target, "Zone equals the target when solved")
                c.equal(play.rods * 10 + play.units, puzzle.target, "Rods and units describe the total")

                var greedy = BarSession(puzzle: puzzle)
                var solvedCount = 0
                for piece in puzzle.bars {
                    let before = greedy.placedTotal
                    let outcome = greedy.place(piece.id)
                    if outcome == .solved { solvedCount += 1 }
                    if outcome == .rejected { c.equal(greedy.placedTotal, before, "Rejected bars leave the zone alone") }
                    c.check(greedy.placedTotal <= puzzle.target, "Zone never passes the target")
                }
                c.check(solvedCount <= 1, "Greedy play solves at most once")
            }
        }
        // Honest hints: from a state reached by random cuts, combines, placements and
        // take-backs, following the hints step by step always solves the task.
        var wander = SeededGenerator(seed: 9_876)
        for maximum in barBuildMaximums {
            for _ in 0..<400 {
                let puzzle = BarPuzzle.makeBuild(maximum: maximum, using: &wander)
                var play = BarSession(puzzle: puzzle)
                for _ in 0..<Int.random(in: 0...14, using: &wander) {
                    guard !play.isSolved, let piece = play.shelf.randomElement(using: &wander) else { break }
                    switch Int.random(in: 0..<4, using: &wander) {
                    case 0:
                        if piece.value > 1 { play.split(piece.id, bottom: Int.random(in: 1..<piece.value, using: &wander)) }
                    case 1:
                        if let other = play.shelf.randomElement(using: &wander) { play.combine(piece.id, onto: other.id) }
                    case 2:
                        play.place(piece.id)
                    default:
                        play.takeBackLast()
                    }
                    c.check(play.placedTotal <= puzzle.target, "Random play never passes the target")
                    c.check(play.shelf.allSatisfy { BarRules.isValidBar($0.value) }, "Every shelf bar stays 1…10")
                    c.check(play.shelf.reduce(0) { $0 + $1.value } > play.remaining || play.isSolved, "The shelf always holds more than the missing amount")
                }
                var steps = 0
                while !play.isSolved, steps < 4 {
                    steps += 1
                    guard let step = play.buildHintStep else {
                        c.check(false, "An unsolved build task always has a hint step")
                        break
                    }
                    c.check(!play.hint.isEmpty && play.hint.count <= 80, "Hints stay short: \(play.hint)")
                    switch step {
                    case .parts(let values), .place(let values):
                        var outcome = AnswerOutcome.ignored
                        for value in values {
                            guard let bar = play.shelf.first(where: { $0.value == value }) else {
                                c.check(false, "Hinted bar \(value) is on the shelf (\(play.shelf.map(\.value)))")
                                break
                            }
                            outcome = play.place(bar.id)
                            c.check(outcome == .progress || outcome == .solved, "A hinted bar is always accepted")
                        }
                        c.equal(outcome, .solved, "Placing the hinted bars solves \(puzzle.target)")
                    case .cut(let value, let bottom):
                        c.check(bottom >= 1 && bottom < value, "A hinted cut leaves two parts")
                        guard let bar = play.shelf.first(where: { $0.value == value }) else {
                            c.check(false, "Hinted cut bar \(value) is on the shelf")
                            break
                        }
                        c.equal(play.split(bar.id, bottom: bottom), .progress, "The hinted cut is allowed")
                        // Then bars complete the zone; when the cut gave back the starting shelf
                        // (an earlier combine undone), the planned parts are named again.
                        switch play.buildHintStep {
                        case .place?, .parts?: break
                        default: c.check(false, "After a hinted cut the hint names bars that complete the zone: \(String(describing: play.buildHintStep))")
                        }
                    case .state:
                        c.check(false, "The plain state is never needed for generated puzzles")
                    }
                }
                c.check(play.isSolved, "Following the hints solves \(puzzle.target) (range \(maximum))")
            }
        }
        for maximum in barSplitMaximums {
            for _ in 0..<500 {
                let puzzle = BarPuzzle.makeSplit(maximum: maximum, using: &generator)
                var play = BarSession(puzzle: puzzle)
                c.equal(play.split(play.shelf[0].id, bottom: puzzle.parts[0]), .solved, "The wanted cut solves \(puzzle.target)")
                var mirrored = BarSession(puzzle: puzzle)
                c.equal(mirrored.split(mirrored.shelf[0].id, bottom: puzzle.parts[1]), .solved, "The mirrored cut solves too")
                var wrongPlay = BarSession(puzzle: puzzle)
                let wrong = (1..<puzzle.target).first { $0 != puzzle.parts[0] && $0 != puzzle.parts[1] }
                if let wrong {
                    c.equal(wrongPlay.split(wrongPlay.shelf[0].id, bottom: wrong), .incorrect, "A different cut is a mistake")
                    c.check(!wrongPlay.isSolved, "Not solved by a wrong cut")
                    c.equal(wrongPlay.combine(wrongPlay.shelf[0].id, onto: wrongPlay.shelf[1].id), .progress, "Joining the parts again is a step")
                    c.equal(wrongPlay.shelf.map(\.value), [puzzle.target], "The whole bar is back")
                    c.equal(wrongPlay.split(wrongPlay.shelf[0].id, bottom: puzzle.parts[0]), .solved, "Then the right cut solves")
                }
            }
        }
    }

    // MARK: Talløyene

    static func checkIslandMap(_ c: LogicChecker) {
        let map = IslandMap.standard
        c.equal(map.islands.count, 6, "Six islands since version 10")
        c.equal(map.nodes.count, 23, "Twenty-three nodes since version 10")
        c.equal(map.nodes.map(\.number), Array(1...23), "Nodes are numbered in order across the map")
        c.equal(Set(map.nodes.map(\.id)).count, map.nodes.count, "Node identifiers are unique")
        c.equal(map.nodes.map(\.id), [
            "bars-build-5", "bars-split-6", "bars-build-10", "bars-split-10",
            "build-20", "pair-20", "split-20", "bars-build-20",
            "build-40", "pair-40", "split-40",
            "build-100", "pair-100", "split-100",
            "place-show-19", "place-show-99", "place-read-99", "place-away-99", "place-show-999", "place-read-9999",
            "balance-pictures", "balance-hybrid", "balance-symbols",
        ], "Node identifiers are storage keys and never change")
        c.equal(ChallengeRules.defaultTaskCount, 4, "Four tasks per node")
        c.equal(map.islands.map(\.number), [1, 2, 3, 4, 5, 6], "Islands are numbered")
        c.equal(map.islands.map(\.title), ["Stolpeøya", "Tjueøya", "Førtiøya", "Hundreøya", "Tusenøya", "Likevektsøya"], "Island titles")
        c.equal(map.islands.map(\.guide), [.snail, .butterfly, .bee, .hedgehog, .hedgehog, .butterfly], "One guide per island (two guides host twice)")
        c.check(map.nodes.allSatisfy { $0.taskCount == ChallengeRules.defaultTaskCount }, "Every node has the default task count")
        c.equal(map.nodes.first?.id, "bars-build-5", "The journey starts with bars to 5")
        c.equal(map.nodes.first?.activity, .barBuild(maximum: 5), "First activity")
        c.equal(map.nodes[13].activity, .split(.hundred), "The number games end with Del opp to 100")
        c.equal(map.nodes[14].activity, .placeValue(.show, .teens), "Place value starts with the teens")
        c.equal(map.nodes[19].activity, .placeValue(.read, .thousands), "Place value ends with reading thousands")
        c.equal(map.nodes[20].activity, .balance(.pictorial), "The balance starts with pictures")
        c.equal(map.nodes.last?.activity, .balance(.symbolic), "The journey ends with symbols")
        c.equal(MapActivity.balance(.hybrid).title, "Likevekt med bilder og tall", "Balance title")
        c.equal(MapActivity.balance(.symbolic).maximum, 30, "Balance maximum: the board's cap")
        c.equal(map.island(containing: map.nodes[14])?.title, "Tusenøya", "Place value lives on Tusenøya")
        c.equal(MapActivity.placeValue(.takeAway, .tens).title, "Ta bort og veksle til 99", "Place-value title")
        c.equal(MapActivity.placeValue(.read, .thousands).maximum, 9_999, "Place-value maximum")
        c.check(map.nodes.contains { $0.activity == .barBuild(maximum: 20) }, "A bar node above ten exercises the tens rod")
        c.equal(map.predecessor(of: map.nodes[0]), nil, "The first node has no predecessor")
        c.equal(map.predecessor(of: map.nodes[1]), map.nodes[0], "Second node follows the first")
        c.equal(map.predecessor(of: map.nodes[4]), map.nodes[3], "Islands chain into each other")
        c.equal(map.island(containing: map.nodes[4])?.id, "twenty", "Node 5 is on the second island")
        c.equal(map.node(withID: "pair-40")?.number, 10, "Lookup by identifier")
        c.equal(map.node(withID: "missing"), nil, "Unknown identifiers return nil")
        c.equal(MapActivity.build(.practice).title, "Bygg tallet til 20", "Build title")
        c.equal(MapActivity.pair(.advanced).title, "Finn tallvennen til 40", "Pair title")
        c.equal(MapActivity.split(.hundred).title, "Del opp til 100", "Split title")
        c.equal(MapActivity.barBuild(maximum: 10).title, "Bygg med stolper til 10", "Bar build title")
        c.equal(MapActivity.barSplit(maximum: 6).title, "Del stolpen til 6", "Bar split title")
        c.equal(MapActivity.barBuild(maximum: 20).maximum, 20, "Activity maximum")
        c.equal(MapActivity.pair(.hundred).maximum, 100, "Level activity maximum")
        for node in map.nodes {
            c.check(node.activity.maximum >= 5, "Every node shows totals of at least 5")
            c.check(!node.activity.title.isEmpty, "Every node has a title")
        }
        c.equal(ChallengeRules.stars(mistakes: 0), 3, "No mistakes: three stars")
        c.equal(ChallengeRules.stars(mistakes: 1), 3, "One mistake: three stars")
        c.equal(ChallengeRules.stars(mistakes: 2), 2, "Two mistakes: two stars")
        c.equal(ChallengeRules.stars(mistakes: 3), 2, "Three mistakes: two stars")
        c.equal(ChallengeRules.stars(mistakes: 4), 1, "Four mistakes: one star")
        c.equal(ChallengeRules.stars(mistakes: 100), 1, "Completion always earns a star")
        c.equal(MapProgress.maximumStars(in: map), 69, "Three stars per node")
    }

    static func checkMapProgress(_ c: LogicChecker) {
        let map = IslandMap.standard
        let nodes = map.nodes
        var progress = MapProgress()
        c.equal(progress.serialized, "", "Empty progress serializes to nothing")
        c.equal(progress.totalStars(in: map), 0, "No stars yet")
        c.check(progress.isUnlocked(nodes[0], in: map), "The first node is always open")
        c.check(!progress.isUnlocked(nodes[1], in: map), "The second node starts locked")
        c.equal(progress.nextNode(in: map), nodes[0], "The first node is next")
        c.check(progress.record(stars: 2, for: nodes[0]), "First result is stored")
        c.equal(progress.stars(for: nodes[0]), 2, "Two stars stored")
        c.check(progress.isCompleted(nodes[0]), "Completed with stars")
        c.check(progress.isUnlocked(nodes[1], in: map), "Completing node 1 unlocks node 2")
        c.check(!progress.isUnlocked(nodes[2], in: map), "Node 3 stays locked")
        c.equal(progress.nextNode(in: map), nodes[1], "Node 2 is next")
        c.check(!progress.record(stars: 1, for: nodes[0]), "A worse result is not stored")
        c.equal(progress.stars(for: nodes[0]), 2, "Best result kept")
        c.check(progress.record(stars: 3, for: nodes[0]), "A better result is stored")
        c.check(!progress.record(stars: 9, for: nodes[0]), "Stars are clamped to three, so 9 is no improvement over 3")
        c.equal(progress.stars(for: nodes[0]), 3, "Clamped to three")
        c.check(!progress.record(stars: 0, for: nodes[1]), "Zero stars never completes a node")
        c.check(!progress.isCompleted(nodes[1]), "Node 2 still open")
        c.equal(progress.serialized, "bars-build-5=3", "Serialized form")
        progress.record(stars: 1, for: nodes[1])
        c.equal(progress.serialized, "bars-build-5=3,bars-split-6=1", "Entries sorted by identifier")
        c.equal(MapProgress(serialized: progress.serialized), progress, "Round trip")
        c.equal(progress.totalStars(in: map), 4, "Total stars")

        let messy = MapProgress(serialized: " bars-split-6 = 9 ,foo,=3,bar=,x=abc,y=-1,z=0,,build-20=2")
        c.equal(messy.stars(for: nodes[1]), 3, "Oversized values are clamped")
        c.equal(messy.stars(for: nodes[4]), 2, "Valid entries survive")
        c.equal(messy.stars(for: nodes[0]), 0, "Unknown entries are dropped")
        c.equal(messy.serialized, "bars-split-6=3,build-20=2", "Damaged entries are dropped on save")
        c.check(!messy.isUnlocked(nodes[1], in: map), "Stars on a later node do not unlock it without its predecessor")
        c.check(messy.isUnlocked(nodes[2], in: map), "A completed predecessor unlocks the next node")
        c.equal(messy.nextNode(in: map), nodes[0], "The first open, incomplete node is next")

        var full = MapProgress()
        for node in nodes { full.record(stars: 3, for: node) }
        c.equal(full.totalStars(in: map), MapProgress.maximumStars(in: map), "All stars")
        c.equal(full.nextNode(in: map), nil, "Nothing left when everything is complete")
        c.check(nodes.allSatisfy { full.isUnlocked($0, in: map) }, "Everything unlocked")
    }

    static func checkChallengeRun(_ c: LogicChecker) {
        var run = ChallengeRun(taskCount: 4)
        c.equal(run.taskCount, 4, "Task count")
        c.check(!run.isComplete, "Not complete at start")
        c.equal(run.stars, 0, "No stars before completion")
        c.equal(run.progressText, "0 av 4 oppgaver løst", "Progress text")
        run.record(.progress)
        run.record(.ignored)
        c.equal(run.mistakes, 0, "Steps are not mistakes")
        run.record(.incorrect)
        run.record(.rejected)
        c.equal(run.mistakes, 2, "Wrong answers and refused pieces count")
        run.record(.solved)
        run.record(.solved)
        c.equal(run.progressText, "2 av 4 oppgaver løst", "Halfway text")
        c.check(!run.isComplete, "Two of four")
        run.record(.solved)
        run.record(.solved)
        c.check(run.isComplete, "Complete after four")
        c.equal(run.stars, 2, "Two mistakes: two stars")
        run.record(.incorrect)
        run.record(.solved)
        c.equal(run.mistakes, 2, "Nothing changes after completion")
        c.equal(run.solved, 4, "Solved count stays")
        c.equal(ChallengeRun(taskCount: 0).taskCount, 1, "At least one task")
        var perfect = ChallengeRun(taskCount: 1)
        perfect.record(.solved)
        c.equal(perfect.stars, 3, "A clean run earns three stars")
        var rough = ChallengeRun(taskCount: 2)
        for _ in 0..<7 { rough.record(.incorrect) }
        rough.record(.solved)
        rough.record(.solved)
        c.equal(rough.stars, 1, "Many mistakes still earn one star")
    }

    static func checkMapCopy(_ c: LogicChecker) {
        c.equal(GameCopy.barBuildPrompt(target: 10), "Bygg 10 med stolpene.", "Bar build prompt")
        c.equal(GameCopy.barSplitPrompt(total: 8, parts: [3, 5]), "Del stolpen 8 i 3 og 5.", "Bar split prompt")
        c.equal(GameCopy.barCombined(2, 3), "2 og 3 ble 5.", "Combine sentence")
        c.equal(GameCopy.barSplitInto(7, 3), "7 ble 3 og 4.", "Split sentence")
        c.equal(GameCopy.barTotal(14), "1 tierstolpe og 4 enere", "Fourteen as rods and units")
        c.equal(GameCopy.barTotal(20), "2 tierstolper", "Twenty as rods")
        c.equal(GameCopy.barTotal(1), "1 ener", "One unit")
        c.equal(GameCopy.barTotal(0), "0 enere", "Empty zone")
        c.equal(GameCopy.barHintPlace([4]), "Du trenger 4 til. Prøv stolpen 4.", "Single bar hint")
        c.equal(GameCopy.barHintPlace([2, 3]), "Prøv stolpene 2 og 3.", "Two bar hint")
        c.equal(GameCopy.stars(0), "Ingen stjerner", "Zero stars")
        c.equal(GameCopy.stars(1), "1 stjerne", "One star")
        c.equal(GameCopy.stars(3), "3 stjerner", "Three stars")
        c.equal(GameCopy.challengeResult(stars: 3), "Du fikk 3 stjerner.", "Result sentence")
        c.equal(GameCopy.challengeResult(stars: 1), "Du fikk 1 stjerne.", "Singular result sentence")
        c.equal(GameCopy.challengeProgress(solved: 1, total: 4), "1 av 4 oppgaver løst", "Progress")
        c.equal(GameCopy.mapNode(number: 3, title: MapActivity.split(.practice).title), "Oppgave 3. Del opp til 20.", "Node sentence")
        c.equal(GameCopy.mapLocked(number: 3), "Låst. Løs oppgave 2 først.", "Locked sentence")
        c.equal(GameCopy.mapTitle, "Talløyene", "Map title")
        c.equal(GameCopy.mapIntro, "Velkommen til Talløyene. Trykk på et tall for å begynne.", "Map intro")
        c.equal(GameCopy.challengeComplete, "Alle oppgavene er løst!", "Completion heading")
        c.equal(GameCopy.challengeToMap, "Tilbake til kartet", "Back to map")
        c.equal(GameCopy.challengeAgain, "Spill igjen", "Play again")
        c.equal(MapGuide.snail.rawValue, "snail", "Guide raw values are stable")
    }

    // MARK: Plassverdi

    static let placeValueTasks: [PlaceValueTask] = [.show, .read, .takeAway]

    static func checkPlaceValuePuzzle(_ c: LogicChecker, _ puzzle: PlaceValuePuzzle) {
        let range = puzzle.level.range
        c.check(range.contains(puzzle.target), "Place-value target \(puzzle.target) outside \(range) for \(puzzle.level)")
        switch puzzle.task {
        case .show:
            c.check(PlaceValueRules.digitSum(puzzle.target) <= PlaceValueRules.maximumDigitSum, "Show task \(puzzle.target) needs at most \(PlaceValueRules.maximumDigitSum) blocks")
            c.equal(puzzle.amount, 0, "Show has no amount")
            c.check(puzzle.choices.isEmpty, "Show has no choices")
            c.equal(puzzle.answer, puzzle.target, "Show answer is the target")
        case .read:
            c.equal(puzzle.choices.count, 4, "Four choices")
            c.equal(Set(puzzle.choices).count, 4, "Distinct choices")
            c.check(puzzle.choices.contains(puzzle.target), "Choices include the number")
            c.check(puzzle.choices.allSatisfy { range.contains($0) }, "Choices stay in the level \(puzzle.choices)")
            // The highest places must be read too: from hundreds upward some choice differs in
            // the hundreds digit, and with thousands some choice differs in the thousands digit.
            func digit(_ number: Int, _ place: Int) -> Int { (number / place) % 10 }
            let others = puzzle.choices.filter { $0 != puzzle.target }
            if puzzle.level == .hundreds || puzzle.level == .thousands {
                c.check(others.contains { digit($0, 100) != digit(puzzle.target, 100) }, "A choice differs in the hundreds for \(puzzle.target): \(puzzle.choices)")
            }
            if puzzle.level == .thousands {
                c.check(others.contains { digit($0, 1000) != digit(puzzle.target, 1000) }, "A choice differs in the thousands for \(puzzle.target): \(puzzle.choices)")
            }
        case .takeAway:
            c.check(PlaceValuePuzzle.isTakeAwayTarget(puzzle.target), "Take away starts above ten with a ten to break: \(puzzle.target)")
            c.check(puzzle.amount > puzzle.target % 10, "Take away must break a ten: amount \(puzzle.amount) above the ones digit of \(puzzle.target)")
            c.check((1...9).contains(puzzle.amount), "Amount is a single digit")
            c.check(puzzle.answer >= 1, "Result stays positive")
            c.equal(puzzle.answer, puzzle.target - puzzle.amount, "Answer is the difference")
        }
    }

    static func checkPlaceValueRules(_ c: LogicChecker) {
        c.equal(PlaceValueUnit.allCases.map(\.value), [1, 10, 100, 1000], "Place values")
        c.equal(PlaceValueUnit.allCases.map(\.title), ["enere", "tiere", "hundrere", "tusenere"], "Place names")
        c.equal(PlaceValueUnit.ones.next, .tens, "Ones carry into tens")
        c.equal(PlaceValueUnit.thousands.next, nil, "Nothing above thousands")
        c.equal(PlaceValueUnit.ones.previous, nil, "Nothing below ones")
        c.check(PlaceValueUnit.ones < PlaceValueUnit.thousands, "Places are ordered")
        c.equal(PlaceValueLevel.allCases.map(\.range), [11...19, 20...99, 100...999, 1000...9999], "Level ranges")
        c.equal(PlaceValueLevel.allCases.map(\.rawValue), [1, 2, 3, 4], "Level identifiers")
        c.equal(PlaceValueLevel.teens.units, [.ones, .tens], "Teens use ones and tens")
        c.equal(PlaceValueLevel.thousands.units, PlaceValueUnit.allCases, "Thousands use every place")
        c.equal(PlaceValueLevel.hundreds.title, "til 999", "Level title")
        c.equal(PlaceValueRules.digitSum(4_709), 20, "Digit sum")
        c.equal(PlaceValueRules.digitSum(0), 0, "Digit sum of zero")
        c.check(PlaceValuePuzzle.isTakeAwayTarget(32), "32 can give away 5")
        c.check(!PlaceValuePuzzle.isTakeAwayTarget(39), "39 has no room for a single-digit amount above 9")
        c.check(!PlaceValuePuzzle.isTakeAwayTarget(405), "405 would need a hundred broken")
        c.check(!PlaceValuePuzzle.isTakeAwayTarget(9), "9 has no ten")

        var blocks = PlaceValueBlocks(number: 4_709)
        c.equal(blocks[.thousands], 4, "Thousands digit")
        c.equal(blocks[.hundreds], 7, "Hundreds digit")
        c.equal(blocks[.tens], 0, "Tens digit")
        c.equal(blocks[.ones], 9, "Ones digit")
        c.equal(blocks.number, 4_709, "Blocks show their number")
        c.check(blocks.isCanonical, "Digits are canonical")
        blocks[.ones] += 1
        c.check(!blocks.isCanonical, "Ten ones are not canonical")
        c.equal(blocks.regroup(), [.ones: 1], "Ten ones carry once")
        c.equal(blocks, PlaceValueBlocks(number: 4_710), "Carry keeps the number")
        var chain = PlaceValueBlocks(ones: 10, tens: 9, hundreds: 9, thousands: 0)
        c.equal(chain.regroup(), [.ones: 1, .tens: 1, .hundreds: 1], "A carry can ripple through every place")
        c.equal(chain, PlaceValueBlocks(number: 1_000), "999 + 1 regroups to 1000")
        var many = PlaceValueBlocks(ones: 25)
        c.equal(many.regroup(), [.ones: 2], "Twenty-five ones carry twice")
        c.equal(many, PlaceValueBlocks(ones: 5, tens: 2), "Two tens and five ones")
        var top = PlaceValueBlocks(thousands: 12)
        c.equal(top.regroup(), [:], "Thousands never regroup")
        c.equal(top.number, 12_000, "Twelve thousands stay")
        var borrowed = PlaceValueBlocks(number: 32)
        c.check(borrowed.borrow(from: .tens), "Borrow a ten")
        c.equal(borrowed, PlaceValueBlocks(ones: 12, tens: 2), "One ten became ten ones")
        c.equal(borrowed.number, 32, "Borrowing keeps the number")
        var five = PlaceValueBlocks(number: 5)
        c.check(!five.borrow(from: .tens), "Nothing to borrow")
        c.check(!five.borrow(from: .ones), "Ones cannot be broken")
        c.equal(five.number, 5, "Failed borrows change nothing")
        c.equal(PlaceValueBlocks(ones: -3, tens: -1).number, 0, "Negative counts are clamped")
        c.equal(PlaceValueBlocks(number: -7), PlaceValueBlocks(), "Negative numbers show nothing")
        c.check(PlaceValueBlocks().isEmpty, "Empty workspace")
    }

    static func checkRandomizedPlaceValue(_ c: LogicChecker, rounds: Int, seed: UInt64) {
        for level in PlaceValueLevel.allCases {
            // Seeded by position, never by hashValue (that changes from process to process).
            for (taskIndex, task) in placeValueTasks.enumerated() {
                var generator = SeededGenerator(seed: seed &+ UInt64(level.rawValue * 10 + taskIndex))
                for _ in 0..<rounds {
                    checkPlaceValuePuzzle(c, PlaceValuePuzzle.make(task: task, level: level, using: &generator))
                }
            }
        }
        for level in PlaceValueLevel.allCases {
            for target in level.range {
                var generator = SeededGenerator(seed: 99 &+ UInt64(target))
                checkPlaceValuePuzzle(c, PlaceValuePuzzle.make(task: .read, level: level, target: target, using: &generator))
                if PlaceValuePuzzle.isTakeAwayTarget(target) {
                    checkPlaceValuePuzzle(c, PlaceValuePuzzle.make(task: .takeAway, level: level, target: target, using: &generator))
                }
            }
        }
        for _ in 0..<20 {
            checkPlaceValuePuzzle(c, PlaceValuePuzzle.make(task: .show, level: .tens))
            checkPlaceValuePuzzle(c, PlaceValuePuzzle.make(task: .read, level: .thousands))
            checkPlaceValuePuzzle(c, PlaceValuePuzzle.make(task: .takeAway, level: .hundreds))
        }
        func sample(seed: UInt64) -> [Int] {
            var generator = SeededGenerator(seed: seed)
            let read = PlaceValuePuzzle.make(task: .read, level: .hundreds, using: &generator)
            let away = PlaceValuePuzzle.make(task: .takeAway, level: .tens, using: &generator)
            return [read.target] + read.choices + [away.target, away.amount]
        }
        c.equal(sample(seed: 12), sample(seed: 12), "Seeded place-value puzzles are reproducible")
    }

    static func checkPlaceValueSession(_ c: LogicChecker) {
        // Show 47 with blocks.
        var show = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .show, level: .tens, target: 47, amount: 0, choices: []))
        c.equal(show.prompt, "Vis tallet 47 med brikkene.", "Show prompt")
        c.check(!show.hasStarted, "Nothing placed yet")
        c.equal(show.hint, "Legg til 4 tiere til.", "Hint names the biggest missing place")
        c.equal(show.add(.hundreds), .ignored, "Hundreds are not offered at this level")
        for _ in 0..<4 { c.equal(show.add(.tens), .progress, "Add a ten") }
        c.equal(show.number, 40, "Four tens")
        c.equal(show.feedback, "Du har 40. Du trenger 7 til.", "Progress feedback")
        c.equal(show.add(.tens), .rejected, "A fifth ten would pass 47")
        c.equal(show.feedback, GameCopy.placeTooMuch, "Too much feedback")
        c.equal(show.number, 40, "Rejected block changes nothing")
        c.equal(show.hint, "Legg til 7 enere til.", "Hint moves to the ones")
        for _ in 0..<6 { show.add(.ones) }
        c.equal(show.removeOne(.ones), .progress, "Take one back")
        c.equal(show.number, 45, "Back to 45")
        c.equal(show.add(.ones), .progress, "46")
        c.equal(show.add(.ones), .solved, "47 solves")
        c.equal(show.feedback, "4 tiere og 7 enere er 47. Flott!", "Solved feedback names the blocks")
        c.equal(show.add(.ones), .ignored, "Locked after solving")
        c.equal(show.removeOne(.ones), .ignored, "Locked removal")

        // Carrying: 39 + 1 regroups ten ones into a ten.
        var carry = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .show, level: .tens, target: 40, amount: 0, choices: []))
        for _ in 0..<3 { carry.add(.tens) }
        for _ in 0..<9 { carry.add(.ones) }
        c.equal(carry.blocks, PlaceValueBlocks(ones: 9, tens: 3), "39 before the carry")
        c.equal(carry.add(.ones), .solved, "The tenth one completes 40")
        c.equal(carry.blocks, PlaceValueBlocks(number: 40), "Regrouped to four tens")
        c.equal(carry.lastCarries, [.ones: 1], "One carry reported for the animation")
        var midway = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .show, level: .hundreds, target: 120, amount: 0, choices: []))
        for _ in 0..<9 { midway.add(.tens) }
        for _ in 0..<9 { midway.add(.ones) }
        c.equal(midway.add(.ones), .progress, "100 is not 120 yet")
        c.equal(midway.blocks, PlaceValueBlocks(number: 100), "Ones carried into tens and tens into hundreds")
        c.equal(midway.lastCarries, [.ones: 1, .tens: 1], "Both carries reported")
        c.equal(midway.feedback, "Ti enere ble én tier. Ti tiere ble én hundrer. Du har 100. Du trenger 20 til.", "Both carries are named")
        c.equal(midway.borrow(.hundreds), .progress, "Breaking a hundred is allowed while showing")
        c.equal(midway.blocks, PlaceValueBlocks(tens: 10), "Ten tens")
        c.equal(midway.number, 100, "Borrowing keeps the number")

        // Read 47.
        var read = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .read, level: .tens, target: 47, amount: 0, choices: [74, 47, 57, 46]))
        c.equal(read.blocks, PlaceValueBlocks(number: 47), "Blocks show the number")
        c.equal(read.prompt, GameCopy.readPrompt, "Read prompt")
        c.equal(read.add(.ones), .ignored, "No adding while reading")
        c.equal(read.answer(74), .incorrect, "Swapped digits are wrong")
        c.equal(read.feedback, GameCopy.readIncorrect, "Wrong feedback")
        c.equal(read.triedChoices, [74], "Tried choice remembered")
        c.check(!read.hasStarted, "A wrong answer does not make the guide react")
        c.equal(read.answer(99), .ignored, "Not a choice")
        c.equal(read.hint, "Tell de største brikkene først: 4 tiere og 7 enere.", "Read hint says what to count")
        let fresh = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .read, level: .tens, target: 47, amount: 0, choices: [74, 47, 57, 46]))
        c.check(!fresh.hint.contains("Prøv igjen"), "No try-again before anything was tried")
        c.equal(read.answer(47), .solved, "47 is right")
        c.equal(read.feedback, "Riktig! Brikkene viser 47.", "Solved feedback")
        c.equal(read.answer(57), .ignored, "Locked after solving")

        // Take away: 32 − 5 needs a broken ten.
        var away = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .takeAway, level: .tens, target: 32, amount: 5, choices: []))
        c.equal(away.prompt, "Du har 32. Ta bort 5.", "Take away prompt")
        c.equal(away.answer, 27, "Answer")
        c.equal(away.hint, "Ta bort 5 enere til.", "Hint counts what is left to remove")
        c.equal(away.removeOne(.ones), .progress, "Remove one")
        c.equal(away.removeOne(.ones), .progress, "Remove another")
        c.equal(away.number, 30, "Two removed")
        c.equal(away.feedback, GameCopy.takeAwayNeedsBorrow, "No ones left: borrow")
        c.equal(away.hint, GameCopy.takeAwayNeedsBorrow, "Hint says to break a ten")
        c.equal(away.removeOne(.ones), .ignored, "Nothing to remove")
        c.equal(away.removeOne(.tens), .rejected, "Removing a whole ten would drop below 27")
        c.equal(away.feedback, GameCopy.placeTooLittle, "Too little feedback")
        c.equal(away.borrow(.tens), .progress, "Break a ten")
        c.equal(away.blocks, PlaceValueBlocks(ones: 10, tens: 2), "Ten ones now")
        c.equal(away.lastBorrow, .tens, "Borrow reported for the animation")
        c.equal(away.feedback, "Én tier ble ti enere. Du har 30. Ta bort 3 til.", "Borrow feedback")
        c.equal(away.borrow(.tens), .rejected, "A second ten is not needed: ten ones cover the 3 left")
        c.equal(away.feedback, GameCopy.takeAwayEnoughOnes, "Enough-ones feedback")
        c.equal(away.blocks, PlaceValueBlocks(ones: 10, tens: 2), "The refused borrow changes nothing")
        var early = PlaceValueSession(puzzle: PlaceValuePuzzle(task: .takeAway, level: .tens, target: 32, amount: 5, choices: []))
        c.equal(early.borrow(.tens), .progress, "Breaking a ten first is fine: 2 ones cannot cover 5")
        c.equal(early.blocks, PlaceValueBlocks(ones: 12, tens: 2), "Twelve ones")
        c.equal(away.removeOne(.ones), .progress, "29")
        c.equal(away.restoreLast(), .progress, "Put one back")
        c.equal(away.number, 30, "Restored")
        for _ in 0..<2 { away.removeOne(.ones) }
        c.equal(away.removeOne(.ones), .solved, "27 solves")
        c.equal(away.feedback, "32 minus 5 er 27. Kjempebra!", "Solved feedback")
        c.equal(away.blocks, PlaceValueBlocks(ones: 7, tens: 2), "Seven ones and two tens")
        c.equal(away.removeOne(.ones), .ignored, "Locked after solving")
        c.equal(away.restoreLast(), .ignored, "Locked restore")

        // Random play at every level and task.
        var generator = SeededGenerator(seed: 2468)
        for level in PlaceValueLevel.allCases {
            for _ in 0..<300 {
                let showPuzzle = PlaceValuePuzzle.make(task: .show, level: level, using: &generator)
                var play = PlaceValueSession(puzzle: showPuzzle)
                let digits = PlaceValueBlocks(number: showPuzzle.target)
                var outcomes: [AnswerOutcome] = []
                for unit in PlaceValueUnit.allCases.reversed() {
                    for _ in 0..<digits[unit] { outcomes.append(play.add(unit)) }
                }
                c.equal(outcomes.last, .solved, "Adding the digits solves \(showPuzzle.target)")
                c.equal(outcomes.filter { $0 == .solved }.count, 1, "Solved once")
                c.check(play.blocks.isCanonical, "Workspace stays canonical")
                c.equal(play.blocks, digits, "Workspace shows the digits")

                var unitsOnly = PlaceValueSession(puzzle: showPuzzle)
                var steps = 0
                while !unitsOnly.isSolved, steps < 20_000 {
                    let outcome = unitsOnly.add(.ones)
                    c.check(outcome == .progress || outcome == .solved, "Adding ones never overshoots")
                    c.check(unitsOnly.blocks.isCanonical, "Every addition regroups")
                    steps += 1
                }
                c.equal(unitsOnly.number, showPuzzle.target, "Ones alone build the target")

                let readPuzzle = PlaceValuePuzzle.make(task: .read, level: level, using: &generator)
                var reader = PlaceValueSession(puzzle: readPuzzle)
                for wrong in readPuzzle.choices where wrong != readPuzzle.target {
                    c.equal(reader.answer(wrong), .incorrect, "Wrong choice stays active")
                }
                c.equal(reader.answer(readPuzzle.target), .solved, "Right choice solves")

                let awayPuzzle = PlaceValuePuzzle.make(task: .takeAway, level: level, using: &generator)
                var remover = PlaceValueSession(puzzle: awayPuzzle)
                var removals = 0
                while !remover.isSolved, removals < 100 {
                    if remover.blocks[.ones] == 0 {
                        c.equal(remover.borrow(.tens), .progress, "Break a ten when the ones run out")
                    }
                    let outcome = remover.removeOne(.ones)
                    c.check(outcome == .progress || outcome == .solved, "Removing ones never drops below the answer")
                    removals += 1
                }
                c.equal(remover.number, awayPuzzle.answer, "Take away reaches the answer")
                c.equal(removals, awayPuzzle.amount, "Exactly the amount is removed")
            }
        }
    }

    static func checkPlaceValueCopy(_ c: LogicChecker) {
        c.equal(GameCopy.blocks(PlaceValueBlocks(number: 1_247)), "1 tusener, 2 hundrere, 4 tiere og 7 enere", "Four places")
        c.equal(GameCopy.blocks(PlaceValueBlocks(number: 40)), "4 tiere", "One place")
        c.equal(GameCopy.blocks(PlaceValueBlocks(number: 1)), "1 ener", "Singular")
        c.equal(GameCopy.blocks(PlaceValueBlocks()), "ingen brikker", "Empty")
        c.equal(GameCopy.regrouped(.ones), "Ti enere ble én tier.", "Carry sentence")
        c.equal(GameCopy.regrouped(.thousands), "", "No carry above thousands")
        c.equal(GameCopy.borrowed(.hundreds), "Én hundrer ble ti tiere.", "Borrow sentence")
        c.equal(GameCopy.takeAwayPrompt(start: 32, amount: 5), "Du har 32. Ta bort 5.", "Take away prompt")
        c.equal(GameCopy.placeHintAdd(.tens, count: 1), "Legg til 1 tier til.", "Singular hint")
        c.equal(PlaceValueTask.takeAway.title, "Ta bort og veksle", "Task title")
    }

    // MARK: Likevekt

    static func checkBalancePuzzle(_ c: LogicChecker, _ puzzle: BalancePuzzle) {
        c.check(puzzle.unknown >= 1, "Hidden number is positive")
        c.check(puzzle.coefficient >= 1, "At least one hidden number")
        c.check(puzzle.leftConstant >= 0, "Left amount is never negative at the start")
        c.equal(puzzle.rightConstant, puzzle.coefficient * puzzle.unknown + puzzle.leftConstant, "Right side balances the left")
        c.check(puzzle.rightConstant <= puzzle.maximum, "The board starts within its maximum")
        switch puzzle.phase {
        case .pictorial:
            c.equal(puzzle.coefficient, 1, "Pictures: one hidden number")
            c.check((1...5).contains(puzzle.unknown) && (1...5).contains(puzzle.leftConstant), "Pictures stay within 5")
            c.check(puzzle.rightConstant <= 10, "Pictures: right side at most 10")
        case .hybrid:
            c.equal(puzzle.coefficient, 1, "Hybrid: one hidden number")
            c.check((1...9).contains(puzzle.unknown) && (1...9).contains(puzzle.leftConstant), "Hybrid stays within 9")
            c.check(puzzle.rightConstant <= 18, "Hybrid: right side at most 18")
        case .symbolic:
            c.check((1...3).contains(puzzle.coefficient), "Symbols: one to three hidden numbers")
            c.check((1...6).contains(puzzle.unknown), "Symbols: hidden number within 6")
            c.check((0...6).contains(puzzle.leftConstant), "Symbols: left amount within 6")
            c.check(puzzle.coefficient > 1 || puzzle.leftConstant > 0, "A single hidden number always has something to cancel")
            c.check(puzzle.rightConstant <= 24, "Symbols: right side at most 24")
        }
        c.check(puzzle.optimalMoves >= 1, "Every board needs at least one move")
        guard let path = BalanceRules.shortestSolution(coefficient: puzzle.coefficient, left: puzzle.leftConstant, right: puzzle.rightConstant, maximum: puzzle.maximum) else {
            c.check(false, "Every generated board is solvable: \(puzzle.coefficient) · \(puzzle.unknown) + \(puzzle.leftConstant)")
            return
        }
        // One check per puzzle, however long its solution, so the total stays the same from run
        // to run (some puzzles here come from the unseeded production generator).
        var board = (coefficient: puzzle.coefficient, left: puzzle.leftConstant, right: puzzle.rightConstant)
        var everyStepAllowedAndBalanced = true
        for move in path {
            guard let next = BalanceRules.apply(move, coefficient: board.coefficient, left: board.left, right: board.right, maximum: puzzle.maximum) else {
                everyStepAllowedAndBalanced = false
                break
            }
            board = next
            if !BalanceRules.isBalanced(unknown: puzzle.unknown, coefficient: board.coefficient, left: board.left, right: board.right) {
                everyStepAllowedAndBalanced = false
            }
        }
        c.check(everyStepAllowedAndBalanced, "Every step of the shortest solution is allowed and keeps the balance")
        c.check(board.coefficient == 1 && board.left == 0 && board.right == puzzle.unknown, "The shortest solution leaves the hidden number alone")
    }

    /// Independent of the breadth-first search: is there a solution of at most `depth` moves?
    private static func solvable(within depth: Int, coefficient: Int, left: Int, right: Int, maximum: Int) -> Bool {
        if coefficient == 1, left == 0 { return true }
        guard depth > 0 else { return false }
        var moves: [BalanceMove] = BalanceRules.cardValues.flatMap { [BalanceMove.add(value: $0, inverse: true), .add(value: $0, inverse: false)] }
        moves += [2, 3].map { BalanceMove.divide(by: $0) }
        for move in moves {
            if let next = BalanceRules.apply(move, coefficient: coefficient, left: left, right: right, maximum: maximum),
               solvable(within: depth - 1, coefficient: next.coefficient, left: next.left, right: next.right, maximum: maximum) {
                return true
            }
        }
        return false
    }

    static func checkBalanceRules(_ c: LogicChecker) {
        c.equal(BalanceRules.cardValues, [1, 2, 5, 10], "Card values")
        c.equal(BalanceRules.cards(for: 7).map(\.value), [5, 2], "Seven is five and two")
        c.check(BalanceRules.cards(for: 7).allSatisfy { !$0.isInverse }, "Board cards are positive")
        c.check(BalanceRules.cards(for: 0).isEmpty, "Zero shows no card")
        c.check(BalanceRules.cards(for: -3).isEmpty, "No card for a negative amount")
        c.equal(Set(BalanceRules.cards(for: 24).map(\.id)).count, 4, "Cards have distinct identities (10, 10, 2, 2)")
        for amount in 0...30 {
            c.equal(BalanceRules.cards(for: amount).map(\.value).reduce(0, +), amount, "Cards show \(amount)")
        }
        c.equal(BalanceCard(value: 5, isInverse: true).signedValue, -5, "Inverse card is negative")
        c.check(BalanceRules.isBalanced(unknown: 4, coefficient: 1, left: 3, right: 7), "4 + 3 = 7")
        c.check(!BalanceRules.isBalanced(unknown: 4, coefficient: 1, left: 3, right: 8), "4 + 3 is not 8")
        c.equal(BalancePhase.allCases.map(BalanceRules.maximumAmount(for:)), [15, 25, 30], "Board maximum per phase")

        // Allowed moves.
        c.check(BalanceRules.apply(.add(value: 5, inverse: true), coefficient: 1, left: 3, right: 7, maximum: 15) == nil, "An inverse card never takes more than the left side holds")
        c.check(BalanceRules.apply(.add(value: 2, inverse: true), coefficient: 1, left: 3, right: 7, maximum: 15).map { [$0.coefficient, $0.left, $0.right] } == [1, 1, 5], "Minus 2 on both sides")
        c.check(BalanceRules.apply(.add(value: 10, inverse: false), coefficient: 1, left: 3, right: 7, maximum: 15) == nil, "No side passes the maximum")
        c.check(BalanceRules.apply(.add(value: 3, inverse: false), coefficient: 1, left: 3, right: 7, maximum: 15) == nil, "Only real cards")
        c.check(BalanceRules.apply(.divide(by: 2), coefficient: 2, left: 3, right: 11, maximum: 30) == nil, "3 cannot be halved")
        c.check(BalanceRules.apply(.divide(by: 2), coefficient: 3, left: 0, right: 15, maximum: 30) == nil, "Three buds cannot be halved")
        c.check(BalanceRules.apply(.divide(by: 2), coefficient: 2, left: 4, right: 10, maximum: 30).map { [$0.coefficient, $0.left, $0.right] } == [1, 2, 5], "Halving 2 · ? + 4 = 10")

        // Shortest solutions, including the ones a fixed recipe would miss.
        func shortest(_ coefficient: Int, _ left: Int, _ right: Int, _ maximum: Int = 30) -> [BalanceMove]? {
            BalanceRules.shortestSolution(coefficient: coefficient, left: left, right: right, maximum: maximum)
        }
        c.equal(shortest(1, 3, 7, 15), [.add(value: 2, inverse: true), .add(value: 1, inverse: true)], "? + 3 = 7: minus 2, minus 1")
        c.equal(shortest(1, 9, 13, 25)?.count, 2, "? + 9 = 13 takes two moves (plus 1, then minus 10)")
        c.equal(shortest(1, 9, 13, 25)?.first, .add(value: 1, inverse: false), "A plus card can shorten the way")
        c.equal(shortest(2, 4, 10)?.first, .divide(by: 2), "Halving first is shorter for 2 · ? + 4 = 10")
        c.equal(shortest(2, 4, 10)?.count, 2, "Halve, then minus 2")
        c.equal(shortest(2, 3, 11)?.count, 3, "3 must go before halving: two cards and a division")
        c.equal(shortest(3, 0, 15), [.divide(by: 3)], "3 · ? = 15: one division")
        c.equal(shortest(1, 0, 4), [], "Solved board")
        c.equal(BalancePuzzle(phase: .symbolic, unknown: 4, coefficient: 2, leftConstant: 7).optimalMoves, 3, "2 · ? + 7 = 15: minus 5, minus 2, halve")
        c.equal(BalancePuzzle(phase: .pictorial, unknown: 2, coefficient: 1, leftConstant: 3).optimalMoves, 2, "? + 3 = 5: two moves")

        // Every board the generators can make: the breadth-first length is the true shortest
        // (no shorter solution exists, checked by an independent depth-limited search).
        var boards: [BalancePuzzle] = []
        for unknown in 1...5 { for left in 1...5 { boards.append(BalancePuzzle(phase: .pictorial, unknown: unknown, coefficient: 1, leftConstant: left)) } }
        for unknown in 1...9 { for left in 1...9 { boards.append(BalancePuzzle(phase: .hybrid, unknown: unknown, coefficient: 1, leftConstant: left)) } }
        for coefficient in 1...3 { for unknown in 1...6 { for left in (coefficient == 1 ? 1 : 0)...6 {
            boards.append(BalancePuzzle(phase: .symbolic, unknown: unknown, coefficient: coefficient, leftConstant: left))
        } } }
        c.equal(boards.count, 25 + 81 + 120, "Every possible board")
        for board in boards {
            let optimal = board.optimalMoves
            c.check(solvable(within: optimal, coefficient: board.coefficient, left: board.leftConstant, right: board.rightConstant, maximum: board.maximum), "A solution of \(optimal) moves exists")
            c.check(!solvable(within: optimal - 1, coefficient: board.coefficient, left: board.leftConstant, right: board.rightConstant, maximum: board.maximum), "No solution is shorter than \(optimal) moves for \(board.coefficient) · \(board.unknown) + \(board.leftConstant)")
            c.check(optimal <= 4, "No board needs more than four moves")
        }

        c.equal(BalanceRules.stars(moves: 2, optimal: 2), 3, "Shortest solution: three stars")
        c.equal(BalanceRules.stars(moves: 1, optimal: 2), 3, "Fewer than expected still three")
        c.equal(BalanceRules.stars(moves: 4, optimal: 2), 2, "Two extra moves: two stars")
        c.equal(BalanceRules.stars(moves: 5, optimal: 2), 1, "Three extra moves: one star")
        c.equal(BalancePhase.allCases.map(\.rawValue), [1, 2, 3], "Phase identifiers")
        c.equal(BalancePhase.symbolic.title, "med tall og tegn", "Phase title")
    }

    static func checkRandomizedBalance(_ c: LogicChecker, rounds: Int, seed: UInt64) {
        for phase in BalancePhase.allCases {
            var generator = SeededGenerator(seed: seed &+ UInt64(phase.rawValue * 100))
            for _ in 0..<rounds {
                checkBalancePuzzle(c, BalancePuzzle.make(phase: phase, using: &generator))
            }
        }
        for _ in 0..<20 {
            checkBalancePuzzle(c, BalancePuzzle.make(phase: .symbolic))
        }
        func sample(seed: UInt64) -> [Int] {
            var generator = SeededGenerator(seed: seed)
            return BalancePhase.allCases.flatMap { phase -> [Int] in
                let puzzle = BalancePuzzle.make(phase: phase, using: &generator)
                return [puzzle.unknown, puzzle.coefficient, puzzle.leftConstant]
            }
        }
        c.equal(sample(seed: 3), sample(seed: 3), "Seeded balance puzzles are reproducible")
    }

    /// Follows the hints from the board as it is; returns the moves used, or nil if a hinted
    /// move was refused.
    private static func followHints(_ play: inout BalanceSession, _ c: LogicChecker) -> Int? {
        var used = 0
        while !play.isSolved, used < 10 {
            guard let move = play.nextMove else { return nil }
            let outcome: AnswerOutcome
            switch move {
            case .add(let value, let inverse): outcome = play.add(value: value, inverse: inverse)
            case .divide(let divisor): outcome = play.divide(by: divisor)
            }
            guard outcome == .progress || outcome == .solved else { return nil }
            used += 1
        }
        return play.isSolved ? used : nil
    }

    static func checkBalanceSession(_ c: LogicChecker) {
        // ? + 3 = 7 with pictures.
        var session = BalanceSession(puzzle: BalancePuzzle(phase: .pictorial, unknown: 4, coefficient: 1, leftConstant: 3))
        c.equal(session.right, 7, "Right side starts at 7")
        c.equal(session.leftCards.map(\.value), [2, 1], "Left shows 2 and 1")
        c.equal(session.rightCards.map(\.value), [5, 2], "Right shows 5 and 2")
        c.equal(session.leftCards.map(\.id), session.leftCards.map(\.id), "Cards keep their identity between reads")
        c.check(session.isBalanced, "Balanced at the start")
        c.equal(session.equation, "knoppen pluss 3 er 7", "Spoken equation")
        c.equal(session.symbols, "? + 3 = 7", "Symbols")
        c.equal(session.hint, "Legg minus 2 på begge sider.", "Hint: the first step of a shortest solution")
        c.equal(session.prompt, "Hva gjemmer seg i knoppen? Legg samme kort på begge sider til knoppen står alene.", "Picture prompt says what to do")
        c.equal(session.goal, "Legg samme kort på begge sider til knoppen står alene.", "The goal in words")
        c.check(session.availableDivisors.isEmpty, "No division rail with one hidden number")
        c.equal(session.add(value: 3, inverse: true), .ignored, "3 is not a card")
        c.equal(session.add(value: 5, inverse: true), .rejected, "Minus 5 would take more than the 3 beside the bud")
        c.equal(session.feedback, "Ved siden av knoppen er det bare 3. Prøv et mindre minuskort.", "Refusal names what is there")
        c.equal(session.moves, 0, "A refused card is not a move")
        let keptRight = session.rightCards.first { $0.value == 5 }!.id
        c.equal(session.add(value: 2, inverse: true), .progress, "Minus 2 on both sides")
        c.equal(session.leftCards.map(\.value), [1], "The 2 beside the bud cancelled")
        c.equal(session.rightCards.map(\.value), [5], "The 2 on the right cancelled")
        c.equal(session.rightCards.first?.id, keptRight, "Untouched cards keep their identity")
        c.equal(session.lastEffect?.takenLeft.map(\.value), [2], "The cancelled card is reported for the animation")
        c.check(session.isBalanced, "Still balanced")
        c.equal(session.feedback, "Du la minus 2 på begge sider. 2 og minus 2 ble null.", "Move feedback")
        c.equal(session.moves, 1, "One move")
        c.equal(session.add(value: 1, inverse: true), .solved, "Minus 1 solves")
        c.equal(session.feedback, "Knoppen åpnet seg: tallet er 4! Du brukte 2 trekk.", "Solved feedback")
        c.equal(session.stars, 3, "Shortest solution earns three stars")
        c.equal(session.right, 4, "Right side shows the hidden number")
        c.equal(session.add(value: 1, inverse: true), .ignored, "Locked after solving")
        c.equal(session.hint, "Knoppen åpnet seg: tallet er 4! Du brukte 2 trekk.", "Hint after solving")

        // A plus card goes on the left and its mirror on the right.
        var mirror = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 4, coefficient: 1, leftConstant: 9))
        c.equal(mirror.hint, "Legg pluss 1 på begge sider.", "Plus 1, then minus 10 is the shortest way for ? + 9 = 13")
        let before = Set(mirror.rightCards.map(\.id))
        c.equal(mirror.add(value: 1, inverse: false), .progress, "Plus 1")
        c.check(before.isSubset(of: Set(mirror.rightCards.map(\.id))), "Cards already there stay")
        c.equal(mirror.lastEffect?.rightCard?.value, 1, "The mirror has the same value")
        c.check(mirror.lastEffect?.rightCard?.id != mirror.lastEffect?.leftCard?.id, "The mirror is a card of its own")
        c.check(mirror.rightCards.contains { $0.id == mirror.lastEffect?.rightCard?.id }, "The mirror lies on the right side")
        c.equal(mirror.feedback, "Du la pluss 1 på begge sider.", "Plus feedback")
        c.equal(mirror.hint, "Legg minus 10 på begge sider.", "Then minus 10")
        c.equal(mirror.add(value: 10, inverse: true), .solved, "Minus 10 solves")
        c.equal(mirror.moves, 2, "Two moves")
        c.equal(mirror.stars, 3, "Shortest")

        // Taking part of a card: the card is changed into smaller ones first.
        var change = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 4, coefficient: 1, leftConstant: 5))
        c.equal(change.leftCards.map(\.value), [5], "Left shows a 5")
        c.equal(change.add(value: 2, inverse: true), .progress, "Minus 2")
        c.equal(change.leftCards.map(\.value).sorted(), [1, 2], "5 became 2 and 1 beside the bud")
        c.equal(change.left, 3, "3 left")
        c.equal(change.right, 7, "7 on the right")
        c.equal(change.feedback, "Du la minus 2 på begge sider. 5 ble 2, 2 og 1. 2 og minus 2 ble null.", "Change feedback")
        c.check(change.leftCards.allSatisfy { !$0.isInverse } && change.rightCards.allSatisfy { !$0.isInverse }, "Only positive cards stay on the board")

        // Change-making always tells what the child sees.
        var partial = BalanceSession(puzzle: BalancePuzzle(phase: .pictorial, unknown: 2, coefficient: 1, leftConstant: 1))
        partial.add(value: 5, inverse: false)
        c.equal(partial.leftCards.map(\.value), [1, 5], "1 and 5 beside the bud")
        c.equal(partial.add(value: 2, inverse: true), .progress, "Minus 2")
        c.equal(partial.leftCards.map(\.value).sorted(), [1, 1, 2], "The 1 stays, the 5 became 2, 2 and 1, one 2 went")
        c.equal(partial.feedback, "Du la minus 2 på begge sider. 5 ble 2, 2 og 1. 2 og minus 2 ble null.", "The sentence matches the board")
        var ten = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 1, coefficient: 1, leftConstant: 2))
        ten.add(value: 10, inverse: false)
        c.equal(ten.add(value: 5, inverse: true), .progress, "Minus 5 from 2 and 10")
        c.equal(ten.leftCards.map(\.value).sorted(), [2, 5], "The 10 became 5 and 5, one 5 went")
        c.equal(ten.feedback, "Du la minus 5 på begge sider. 10 ble 5 og 5. 5 og minus 5 ble null.", "Only card values are named")
        c.check(ten.isBalanced, "Balanced")
        var wholeCards = BalanceSession(puzzle: BalancePuzzle(phase: .pictorial, unknown: 2, coefficient: 1, leftConstant: 1))
        wholeCards.add(value: 1, inverse: false)
        wholeCards.add(value: 10, inverse: false)
        c.equal(wholeCards.add(value: 2, inverse: true), .progress, "Minus 2 from 1, 1 and 10")
        c.equal(wholeCards.leftCards.map(\.value), [10], "The two ones went, the 10 was not broken")
        c.equal(wholeCards.feedback, "Du la minus 2 på begge sider. 2 og minus 2 ble null.", "No change to tell")
        var twos = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 1, coefficient: 1, leftConstant: 2))
        twos.add(value: 2, inverse: false)
        twos.add(value: 2, inverse: false)
        c.equal(twos.add(value: 5, inverse: true), .progress, "Minus 5 from three 2s")
        c.equal(twos.leftCards.map(\.value), [1], "Two 2s went and the third became 1 and 1")
        c.equal(twos.feedback, "Du la minus 5 på begge sider. 2 ble 1 og 1. 5 og minus 5 ble null.", "The last card's change is named")

        // No side keeps more than five cards: more are gathered into the fewest cards.
        var pile = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 9, coefficient: 1, leftConstant: 1))
        for _ in 0..<4 { pile.add(value: 1, inverse: false) }
        c.equal(pile.leftCards.count, 5, "Five ones beside the bud stay as they are")
        c.equal(pile.add(value: 1, inverse: false), .progress, "A sixth one")
        c.check(pile.leftCards.count <= BalanceSession.maximumCardsPerSide && pile.rightCards.count <= BalanceSession.maximumCardsPerSide, "At most five cards per side")
        c.equal(pile.leftCards.map(\.value), [5, 1], "Six ones beside the bud were gathered into 5 and 1")
        c.check(pile.feedback?.hasSuffix(GameCopy.balanceGathered) == true, "Gathering is told")
        c.check(pile.isBalanced, "Gathering keeps the balance")

        // What the node's rating hears.
        c.equal(partial.challengeReports(for: .rejected), [AnswerOutcome](), "A refused move costs nothing")
        c.equal(partial.challengeReports(for: .progress), [AnswerOutcome.progress], "A move is a step")
        var rated = BalanceSession(puzzle: BalancePuzzle(phase: .pictorial, unknown: 2, coefficient: 1, leftConstant: 2))
        rated.add(value: 1, inverse: false)
        rated.add(value: 1, inverse: true)
        rated.add(value: 1, inverse: true)
        c.equal(rated.add(value: 1, inverse: true), .solved, "Solved in four moves where one was enough")
        c.equal(rated.stars, 1, "Three extra moves: one star")
        c.equal(rated.challengeReports(for: .solved), [.incorrect, .incorrect, .solved], "Two missing stars are two mistakes, then the solve")
        var node = ChallengeRun(taskCount: 4)
        for _ in 0..<4 { for report in [AnswerOutcome.incorrect, .solved] { node.record(report) } }
        c.equal(node.stars, 1, "Four boards with one missing star each give one star, like four tasks with a mistake each")

        // The board's maximum.
        var full = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 9, coefficient: 1, leftConstant: 9))
        c.equal(full.add(value: 10, inverse: false), .rejected, "28 would pass the maximum of 25")
        c.equal(full.feedback, GameCopy.balanceTooFull, "Too-full feedback")
        c.equal(full.moves, 0, "Not a move")

        // 2 · ? + 3 = 11 with symbols.
        var division = BalanceSession(puzzle: BalancePuzzle(phase: .symbolic, unknown: 4, coefficient: 2, leftConstant: 3))
        c.equal(division.symbols, "2 · ? + 3 = 11", "Symbols with a coefficient")
        c.equal(division.equation, "2 knopper pluss 3 er 11", "Spoken with two hidden numbers")
        c.equal(division.prompt, "Hva gjemmer seg i knoppene? Hver knopp gjemmer det samme tallet. Legg samme kort på begge sider, eller del begge sidene likt, til én knopp står alene.", "Symbol prompt with two buds")
        c.equal(division.add(value: 5, inverse: true), .rejected, "Minus 5 is more than the 3 beside the buds")
        c.equal(division.feedback, "Ved siden av knoppene er det bare 3. Prøv et mindre minuskort.", "Refusal names the buds in the plural")
        c.equal(division.availableDivisors, [2], "The rail offers halves")
        c.equal(division.divide(by: 3), .ignored, "Thirds are not offered for two buds")
        c.equal(division.divide(by: 2), .rejected, "3 cannot be halved yet")
        c.equal(division.feedback, "3 kan ikke deles i 2 like deler. Legg kort på begge sider først.", "Refused division names the amount")
        c.equal(division.moves, 0, "A refused division is not a move")
        c.equal(followHints(&division, c), 3, "Two cards and a division")
        c.equal(division.coefficient, 1, "One hidden number")
        c.equal(division.right, 4, "The hidden number")
        c.equal(division.lastEffect?.divisor, 2, "Division reported")
        c.equal(division.stars, 3, "Shortest")
        c.equal(division.divide(by: 2), .ignored, "Locked after solving")

        // Halving first: 2 · ? + 4 = 10.
        var halves = BalanceSession(puzzle: BalancePuzzle(phase: .symbolic, unknown: 3, coefficient: 2, leftConstant: 4))
        c.equal(halves.hint, "Del begge sidene i 2 like deler.", "Halving first is the shortest way")
        c.equal(halves.divide(by: 2), .progress, "Halved")
        c.equal(halves.symbols, "? + 2 = 5", "Halved board")
        c.equal(halves.leftCards.map(\.value), [2], "New cards after the division")
        c.equal(halves.add(value: 2, inverse: true), .solved, "Then minus 2")
        c.equal(halves.stars, 3, "Two moves, three stars")

        var thirds = BalanceSession(puzzle: BalancePuzzle(phase: .symbolic, unknown: 5, coefficient: 3, leftConstant: 0))
        c.equal(thirds.availableDivisors, [3], "Three buds: thirds")
        c.equal(thirds.hint, "Del begge sidene i 3 like deler.", "Hint divides by three")
        c.equal(thirds.divide(by: 3), .solved, "Thirds solve 3 · ? = 15")
        c.equal(thirds.right, 5, "Hidden number")

        var slow = BalanceSession(puzzle: BalancePuzzle(phase: .hybrid, unknown: 6, coefficient: 1, leftConstant: 3))
        slow.add(value: 1, inverse: false)
        slow.add(value: 1, inverse: true)
        slow.add(value: 1, inverse: false)
        slow.add(value: 1, inverse: true)
        slow.add(value: 2, inverse: true)
        c.equal(slow.add(value: 1, inverse: true), .solved, "Solved after wandering")
        c.equal(slow.moves, 6, "Six moves")
        c.equal(slow.stars, 1, "Four extra moves: one star")

        // Random play at every phase: whatever happened before, the board stays honest and the
        // hints finish it in exactly the shortest number of moves from there.
        var generator = SeededGenerator(seed: 1357)
        let anyMove: [BalanceMove] = BalanceRules.cardValues.flatMap { [BalanceMove.add(value: $0, inverse: true), .add(value: $0, inverse: false)] } + [.divide(by: 2), .divide(by: 3)]
        for phase in BalancePhase.allCases {
            for _ in 0..<500 {
                let puzzle = BalancePuzzle.make(phase: phase, using: &generator)
                var play = BalanceSession(puzzle: puzzle)
                c.equal(followHints(&play, c), puzzle.optimalMoves, "Hints use the shortest solution")
                c.equal(play.stars, 3, "Shortest solution: three stars")
                c.equal(play.right, puzzle.unknown, "The right side ends as the hidden number")

                var wander = BalanceSession(puzzle: puzzle)
                for _ in 0..<Int.random(in: 0...6, using: &generator) {
                    guard !wander.isSolved else { break }
                    let movesBefore = wander.moves
                    let outcome: AnswerOutcome
                    switch anyMove.randomElement(using: &generator)! {
                    case .add(let value, let inverse): outcome = wander.add(value: value, inverse: inverse)
                    case .divide(let divisor): outcome = wander.divide(by: divisor)
                    }
                    c.equal(wander.moves, movesBefore + (outcome == .progress || outcome == .solved ? 1 : 0), "Only accepted moves count")
                    c.check(wander.isBalanced, "Every move keeps the balance")
                    c.check(wander.left >= 0 && wander.right <= puzzle.maximum, "Amounts stay between 0 and the maximum")
                    c.check(wander.leftCards.allSatisfy { !$0.isInverse } && wander.rightCards.allSatisfy { !$0.isInverse }, "Only positive cards rest on the board")
                    c.equal(Set(wander.leftCards.map(\.id)).count, wander.leftCards.count, "Card identities are unique")
                    c.check(wander.leftCards.count <= BalanceSession.maximumCardsPerSide && wander.rightCards.count <= BalanceSession.maximumCardsPerSide, "At most five cards per side")
                }
                if !wander.isSolved {
                    let expected = BalanceRules.shortestSolution(coefficient: wander.coefficient, left: wander.left, right: wander.right, maximum: puzzle.maximum)?.count
                    c.equal(followHints(&wander, c), expected, "From any board the hints take the shortest way")
                }
                c.check(wander.isSolved, "Every board can be finished")
            }
        }
    }

    static func checkBalanceCopy(_ c: LogicChecker) {
        c.equal(GameCopy.balanceSymbols(coefficient: 1, left: 0, right: 4), "? = 4", "Solved symbols")
        c.equal(GameCopy.balanceSymbols(coefficient: 3, left: 1, right: 13), "3 · ? + 1 = 13", "Coefficient")
        c.equal(GameCopy.balanceEquation(coefficient: 1, left: 0, right: 4), "knoppen er 4", "Solved sentence")
        c.equal(GameCopy.balancePrompt(coefficient: 1), "Hva gjemmer seg i knoppen? Legg samme kort på begge sider til knoppen står alene.", "Prompt with one bud")
        c.equal(GameCopy.balanceAdded(value: 5, inverse: true), "Du la minus 5 på begge sider.", "Added sentence")
        c.equal(GameCopy.balanceDivided(by: 2), "Begge sidene ble delt i 2 like deler.", "Division sentence")
        c.equal(GameCopy.balanceTooMuchAway(left: 0, coefficient: 1), "Det er ingenting å ta bort ved siden av knoppen.", "Nothing beside the bud")
        c.equal(GameCopy.balanceTooMuchAway(left: 0, coefficient: 3), "Det er ingenting å ta bort ved siden av knoppene.", "Nothing beside the buds")
        c.equal(GameCopy.balanceTooFull, "Så mye får ikke plass på vekten. Prøv et mindre kort.", "Too-full sentence names the rule")
        c.equal(GameCopy.balanceSolved(unknown: 3, moves: 1), "Knoppen åpnet seg: tallet er 3! Du brukte 1 trekk.", "Singular move")
        c.equal(GameCopy.moves(4), "4 trekk", "Moves")
    }

    // MARK: Everything

    static func runAll(_ c: LogicChecker, rounds: Int, seed: UInt64) {
        checkLevels(c)
        checkRandomizedGeneration(c, rounds: rounds, seed: seed)
        checkExhaustiveTargets(c)
        checkDeterminism(c)
        checkWorkshopRules(c)
        checkCompletionSearch(c)
        checkBuildSession(c)
        checkPairSession(c)
        checkSplitSession(c)
        checkWorkshopSession(c)
        checkCopy(c)
        checkBarRules(c)
        checkRandomizedBars(c, rounds: rounds, seed: seed)
        checkBarSession(c)
        checkIslandMap(c)
        checkMapProgress(c)
        checkChallengeRun(c)
        checkMapCopy(c)
        checkPlaceValueRules(c)
        checkRandomizedPlaceValue(c, rounds: rounds, seed: seed)
        checkPlaceValueSession(c)
        checkPlaceValueCopy(c)
        checkBalanceRules(c)
        checkRandomizedBalance(c, rounds: rounds, seed: seed)
        checkBalanceSession(c)
        checkBalanceCopy(c)
    }
}
