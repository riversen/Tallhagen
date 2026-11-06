import XCTest
@testable import Tallhagen

// Xcode unit tests. The invariant checks themselves live in Tests/LogicChecks.swift and are
// shared with the swiftc-only runner (`./Tests/run.sh`); here every failed check becomes an
// XCTFail with its message. The randomized round count is lower than the standalone run so
// the suite stays fast on a simulator, and the seed is fixed for reproducibility.

private func makeChecker() -> LogicChecker {
    LogicChecker { message in XCTFail(message) }
}

final class LearningLevelTests: XCTestCase {
    func testLevelIdentifiersTitlesAndMaxima() {
        LogicChecks.checkLevels(makeChecker())
    }

    func testStoredLevelReadsUserDefaultsAndFallsBack() throws {
        let suite = "TallhagenTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(LearningLevel.stored(in: defaults), .practice, "Nothing stored yet")
        for level in LearningLevel.allCases {
            defaults.set(level.rawValue, forKey: StorageKey.learningLevel)
            XCTAssertEqual(LearningLevel.stored(in: defaults), level)
        }
        defaults.set(99, forKey: StorageKey.learningLevel)
        XCTAssertEqual(LearningLevel.stored(in: defaults), .practice, "Unknown values fall back")
        defaults.set("tekst", forKey: StorageKey.learningLevel)
        XCTAssertEqual(LearningLevel.stored(in: defaults), .practice, "Wrong types fall back")
    }

    func testStorageKeysAreStable() {
        XCTAssertEqual(StorageKey.learningLevel, "learningLevel")
        XCTAssertEqual(StorageKey.speakNorwegian, "speakNorwegian")
        XCTAssertEqual(StorageKey.solvedTotal, "solvedTotal")
    }
}

final class PuzzleGeneratorTests: XCTestCase {
    func testRandomizedGenerationStaysWithinEveryLevel() {
        LogicChecks.checkRandomizedGeneration(makeChecker(), rounds: 2_000, seed: 2026)
    }

    func testEveryTargetThroughFortyCanBeProduced() {
        LogicChecks.checkExhaustiveTargets(makeChecker())
    }

    func testSeededGenerationIsReproducible() {
        LogicChecks.checkDeterminism(makeChecker())
    }

    func testCompletionSearch() {
        LogicChecks.checkCompletionSearch(makeChecker())
    }

    func testBoundaryTargets() {
        var generator = SeededGenerator(seed: 1)
        let smallest = BuildPuzzle.make(level: .start, target: 5, using: &generator)
        XCTAssertEqual(smallest.target, 5)
        XCTAssertTrue(smallest.pieces.allSatisfy { (1...4).contains($0.value) })

        let largest = BuildPuzzle.make(level: .advanced, target: 40, using: &generator)
        XCTAssertEqual(largest.target, 40)
        XCTAssertTrue(largest.pieces.allSatisfy { (1...39).contains($0.value) })

        let pair = PairPuzzle.make(level: .advanced, target: 40, using: &generator)
        XCTAssertEqual(pair.given + pair.answer, 40)
        XCTAssertTrue(pair.choices.allSatisfy { (1...39).contains($0) })

        let split = SplitPuzzle.make(level: .advanced, total: 40, using: &generator)
        XCTAssertEqual(split.wantedLeft + split.wantedRight, 40)
        XCTAssertEqual(split.leftRange, 1...39)
    }
}

final class WorkshopRulesTests: XCTestCase {
    func testWorkshopRulesAtEveryMaximum() {
        LogicChecks.checkWorkshopRules(makeChecker())
    }

    func testFortyIsReachableAndFortyOneIsNot() {
        XCTAssertTrue(WorkshopRules.isValid(first: 39, second: 1, maximum: 40))
        XCTAssertTrue(WorkshopRules.isValid(first: 20, second: 20, maximum: 40))
        XCTAssertFalse(WorkshopRules.canIncrease(first: 39, second: 1, maximum: 40))
        XCTAssertFalse(WorkshopRules.isValid(first: 39, second: 2, maximum: 40))
    }
}

final class GameSessionTests: XCTestCase {
    func testBuildSession() {
        LogicChecks.checkBuildSession(makeChecker())
    }

    func testPairSession() {
        LogicChecks.checkPairSession(makeChecker())
    }

    func testSplitSession() {
        LogicChecks.checkSplitSession(makeChecker())
    }

    func testWorkshopSession() {
        LogicChecks.checkWorkshopSession(makeChecker())
    }

    func testNorwegianCopy() {
        LogicChecks.checkCopy(makeChecker())
    }

    func testSolvedIsReportedExactlyOncePerPuzzle() {
        var generator = SeededGenerator(seed: 8)
        for level in LearningLevel.allCases {
            let puzzle = PairPuzzle.make(level: level, using: &generator)
            var session = PairSession(puzzle: puzzle)
            var solvedReports = 0
            for choice in puzzle.choices + puzzle.choices {
                if session.answer(choice) == .solved { solvedReports += 1 }
            }
            XCTAssertEqual(solvedReports, 1, "The solved counter must only ever be incremented once")
        }
    }
}

// MARK: - Voice choice

/// The Norwegian voice is chosen from plain candidates, so the rule is testable without
/// downloading voices: Bokmål first, then the highest quality; personal and novelty voices never.
final class VoiceSelectionTests: XCTestCase {
    private func voice(_ identifier: String, _ language: String, quality: Int, usable: Bool = true) -> VoiceCandidate {
        VoiceCandidate(identifier: identifier, language: language, quality: quality, isUsable: usable)
    }

    func testPrefersTheHighestQualityBokmalVoice() {
        let best = NorwegianVoice.bestNorwegianVoice(among: [
            voice("compact", "nb-NO", quality: 1),
            voice("premium", "nb-NO", quality: 3),
            voice("enhanced", "nb-NO", quality: 2),
        ])
        XCTAssertEqual(best?.identifier, "premium")
    }

    func testBokmalBeatsOtherNorwegianTagsEvenAtLowerQuality() {
        let best = NorwegianVoice.bestNorwegianVoice(among: [
            voice("nynorsk-premium", "nn-NO", quality: 3),
            voice("bokmal-compact", "nb-NO", quality: 1),
        ])
        XCTAssertEqual(best?.identifier, "bokmal-compact")
    }

    func testFallsBackToAnyNorwegianAndIgnoresOtherLanguagesAndUnusableVoices() {
        let best = NorwegianVoice.bestNorwegianVoice(among: [
            voice("english", "en-US", quality: 3),
            voice("personal", "nb-NO", quality: 3, usable: false),
            voice("old-tag", "no-NO", quality: 2),
        ])
        XCTAssertEqual(best?.identifier, "old-tag")
        XCTAssertNil(NorwegianVoice.bestNorwegianVoice(among: [voice("english", "en-US", quality: 3)]))
        XCTAssertNil(NorwegianVoice.bestNorwegianVoice(among: []))
    }

    func testLanguageTagsAreMatchedCaseInsensitively() {
        XCTAssertTrue(NorwegianVoice.isNorwegian("NB-no"))
        XCTAssertTrue(NorwegianVoice.isBokmal("nb"))
        XCTAssertFalse(NorwegianVoice.isBokmal("nn-NO"))
        XCTAssertFalse(NorwegianVoice.isNorwegian("nl-NL"))
    }
}

// MARK: - Tallstolpene and Talløyene (version 8)

final class NumberBarTests: XCTestCase {
    func testBarRulesAndRanges() {
        LogicChecks.checkBarRules(makeChecker())
    }

    func testRandomizedBarPuzzlesStayWithinTheirNodes() {
        LogicChecks.checkRandomizedBars(makeChecker(), rounds: 1_000, seed: 2026)
    }

    func testBarSession() {
        LogicChecks.checkBarSession(makeChecker())
    }
}

final class IslandMapTests: XCTestCase {
    func testMapContentAndStarRules() {
        LogicChecks.checkIslandMap(makeChecker())
    }

    func testProgressStarsAndUnlocks() {
        LogicChecks.checkMapProgress(makeChecker())
    }

    func testChallengeRun() {
        LogicChecks.checkChallengeRun(makeChecker())
    }

    func testMapCopy() {
        LogicChecks.checkMapCopy(makeChecker())
    }

    func testIslandStarsKeyIsStableAndRoundTripsThroughUserDefaults() throws {
        XCTAssertEqual(StorageKey.islandStars, "islandStars")
        let suite = "TallhagenTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertNil(defaults.string(forKey: StorageKey.islandStars), "Nothing stored in a fresh suite")
        XCTAssertEqual(MapProgress(serialized: ""), MapProgress(), "An empty value is a fresh map")
        var progress = MapProgress()
        let map = IslandMap.standard
        progress.record(stars: 3, for: map.nodes[0])
        progress.record(stars: 1, for: map.nodes[1])
        defaults.set(progress.serialized, forKey: StorageKey.islandStars)
        let restored = MapProgress(serialized: defaults.string(forKey: StorageKey.islandStars) ?? "")
        XCTAssertEqual(restored, progress, "Stars survive a round trip through UserDefaults")
        XCTAssertTrue(restored.isUnlocked(map.nodes[2], in: map), "Unlocks are derived from the stored stars")
        XCTAssertFalse(restored.isUnlocked(map.nodes[3], in: map))
    }
}

// MARK: - Plassverdi (version 9)

final class PlaceValueTests: XCTestCase {
    func testRulesBlocksAndLevels() {
        LogicChecks.checkPlaceValueRules(makeChecker())
    }

    func testRandomizedPuzzlesStayWithinTheirLevels() {
        LogicChecks.checkRandomizedPlaceValue(makeChecker(), rounds: 500, seed: 2026)
    }

    func testSessionCarriesBorrowsReadsAndTakesAway() {
        LogicChecks.checkPlaceValueSession(makeChecker())
    }

    func testCopy() {
        LogicChecks.checkPlaceValueCopy(makeChecker())
    }
}

// MARK: - Likevekt (version 10)

final class BalanceTests: XCTestCase {
    func testRulesCardsAndStars() {
        LogicChecks.checkBalanceRules(makeChecker())
    }

    func testRandomizedBoardsStayWithinTheirPhases() {
        LogicChecks.checkRandomizedBalance(makeChecker(), rounds: 500, seed: 2026)
    }

    func testSessionMirrorsCancelsDividesAndSolves() {
        LogicChecks.checkBalanceSession(makeChecker())
    }

    func testCopy() {
        LogicChecks.checkBalanceCopy(makeChecker())
    }
}
