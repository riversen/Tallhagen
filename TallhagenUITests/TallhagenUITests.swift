import XCTest

// UI tests drive the real app on an iPad simulator. Puzzles are random, so the tests read the
// numbers shown on screen (through accessibility identifiers) and act on them. The level is
// pinned per test through UserDefaults launch arguments; nothing is changed in the app for tests.

final class TallhagenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // A simulator keeps its last orientation; the flows below assume portrait.
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
    }

    // MARK: Helpers

    /// Launches with speech off. A level given here is pinned through the UserDefaults argument
    /// domain for this process only; the solved counter is never pinned, because an argument
    /// value would shadow the app's own writes for the whole run.
    private func launch(level: LearningLevel? = nil, quiet: Bool = true) {
        // Most tests silence speech through the argument domain; the sound-button test must not,
        // because that argument would shadow the app's own default and its writes.
        if quiet {
            app.launchArguments += ["-speakNorwegian", "0"]
        }
        if let level {
            app.launchArguments += ["-learningLevel", "\(level.rawValue)"]
        }
        app.launch()
        // A fresh install opens the level chooser first; pick Til 20 so the home screen appears.
        let firstChoice = app.buttons["start.level.2"]
        if firstChoice.waitForExistence(timeout: 2) {
            firstChoice.tap()
        }
        // Generous: a cold launch on a busy Mac (a parallel build, two simulators) can take a while.
        XCTAssertTrue(app.staticTexts["Velg en lek"].waitForExistence(timeout: 20), "Home screen")
    }

    /// Any element carrying an accessibility identifier, whatever its element type.
    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private enum LearningLevel: Int { case start = 1, practice, challenge, advanced, hundred }

    private func open(_ game: String) {
        let card = app.buttons["home.game.\(game)"]
        XCTAssertTrue(card.waitForExistence(timeout: 5), "Game card \(game)")
        card.tap()
        XCTAssertTrue(app.buttons["game.back"].waitForExistence(timeout: 5), "Game screen opened")
    }

    /// Scrolls the game content towards the element until it is hittable, then taps it.
    private func tapScrollingIfNeeded(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Element exists: \(element)", file: file, line: line)
        scrollUntilHittable(element)
        XCTAssertTrue(element.isHittable, "Element hittable: \(element)", file: file, line: line)
        element.tap()
    }

    /// Swipes down when the element sits above the viewport and up when it sits below.
    private func scrollUntilHittable(_ element: XCUIElement) {
        var attempts = 0
        while !element.isHittable, attempts < 8 {
            if element.exists, element.frame.minY < app.frame.minY + 40 {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
            attempts += 1
        }
    }

    /// Brings a lazily rendered card grid on screen (its header is hittable) before counting cards.
    private func revealGrid(headed header: String) {
        let heading = app.staticTexts[header]
        XCTAssertTrue(heading.waitForExistence(timeout: 5), "Grid header \(header)")
        scrollUntilHittable(heading)
    }

    /// Keeps a full screenshot in the result bundle (section 10 lists the screens checked this way).
    private func keepScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func numbers(in text: String) -> [Int] {
        text.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
    }

    private func firstNumber(of element: XCUIElement) -> Int {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Element with a number: \(element)")
        guard let value = numbers(in: element.label).first else {
            XCTFail("No number in label '\(element.label)'")
            return 0
        }
        return value
    }

    private func solvedTotalOnHome() -> Int {
        firstNumber(of: element("home.solvedTotal"))
    }

    // MARK: Home and settings

    func testHomeShowsFourActivitiesAndLevel() {
        launch(level: .practice)
        let expected = [
            "build": "Bygg tallet", "pair": "Finn tallvennen", "split": "Del opp", "workshop": "Tallverkstedet",
        ]
        for (key, title) in expected {
            let card = app.buttons["home.game.\(key)"]
            XCTAssertTrue(card.exists, "Activity \(title) is listed")
            XCTAssertTrue(card.label.hasPrefix(title), "Card label starts with \(title): \(card.label)")
        }
        XCTAssertTrue(element("home.level").exists)
        XCTAssertEqual(element("home.level").label, "Valgt nivå: Til 20")
    }

    func testSettingsOffersFourLevelsAndPersistsAcrossRelaunch() {
        launch()
        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.navigationBars["Innstillinger"].waitForExistence(timeout: 5))
        for title in ["Til 10", "Til 20", "Til 30", "Til 40"] {
            XCTAssertTrue(app.buttons[title].exists, "Level choice \(title)")
        }
        app.buttons["Til 30"].tap()
        XCTAssertTrue(element("settings.levelDetail").label.contains("Til 30"))
        app.buttons["settings.done"].tap()
        XCTAssertTrue(element("home.level").waitForExistence(timeout: 5))
        XCTAssertEqual(element("home.level").label, "Valgt nivå: Til 30")

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(element("home.level").waitForExistence(timeout: 10))
        XCTAssertEqual(element("home.level").label, "Valgt nivå: Til 30", "Level survives relaunch")

        // Leave the device on the default level for the next test run.
        app.buttons["home.settings"].tap()
        app.buttons["Til 20"].tap()
        app.buttons["settings.done"].tap()
    }

    func testLevelChooserOffersThreeRangesAndSoundButtonToggles() {
        // No launch arguments at all: the stored level and sound setting must really change.
        // The simulator keeps the app's stored sound setting between runs, so the test starts
        // from whatever it finds, flips it and restores it; the on-by-default behaviour of a
        // fresh install is a manual acceptance check (agent.md section 11).
        launch(quiet: false)
        let sound = app.buttons["sound.toggle"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5), "Sound button is on screen")
        let initialSound = sound.label
        XCTAssertTrue(["Lyd er på", "Lyd er av"].contains(initialSound), "Sound button states its setting")
        let flippedSound = initialSound == "Lyd er på" ? "Lyd er av" : "Lyd er på"
        sound.tap()
        XCTAssertEqual(sound.label, flippedSound, "One tap flips the sound setting")

        app.buttons["home.chooseLevel"].tap()
        for id in ["start.level.2", "start.level.4", "start.level.5"] {
            XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 5), "Choice \(id)")
        }
        XCTAssertTrue(app.buttons["start.level.5"].label.hasPrefix("Til 100"))
        app.buttons["start.level.5"].tap()
        XCTAssertTrue(element("home.level").waitForExistence(timeout: 5))
        XCTAssertEqual(element("home.level").label, "Valgt nivå: Til 100", "Chooser stores Til 100")

        open("workshop")
        let instruction = element("workshop.instruction")
        XCTAssertTrue(instruction.waitForExistence(timeout: 5))
        XCTAssertTrue(instruction.label.contains("opp til 100"), "Workshop cap follows the new level")
        tapScrollingIfNeeded(app.buttons["game.back"])

        // Put the device back the way most tests expect it.
        app.buttons["home.chooseLevel"].tap()
        XCTAssertTrue(app.buttons["start.level.2"].waitForExistence(timeout: 5))
        app.buttons["start.level.2"].tap()
        XCTAssertEqual(element("home.level").label, "Valgt nivå: Til 20")
        sound.tap()
        XCTAssertEqual(sound.label, initialSound, "Sound setting restored")
    }

    // MARK: Tallverkstedet

    func testWorkshopReachesExactlyFortyAndNeverFortyOne() {
        launch(level: .advanced)
        open("workshop")

        let firstPlus = app.buttons["workshop.first.increase"]
        let secondPlus = app.buttons["workshop.second.increase"]
        let secondMinus = app.buttons["workshop.second.decrease"]
        let equation = element("workshop.equation")
        XCTAssertTrue(equation.waitForExistence(timeout: 5))
        XCTAssertEqual(equation.label, "3 pluss 4 er 7.")

        var guardCount = 0
        while firstPlus.isEnabled, guardCount < 60 {
            firstPlus.tap()
            guardCount += 1
        }
        XCTAssertEqual(equation.label, "36 pluss 4 er 40.", "Increments stop exactly at 40")
        XCTAssertFalse(firstPlus.isEnabled, "First + is disabled at 40")
        XCTAssertFalse(secondPlus.isEnabled, "Second + is disabled at 40")

        for _ in 0..<3 { secondMinus.tap() }
        XCTAssertEqual(equation.label, "36 pluss 1 er 37.")
        XCTAssertFalse(secondMinus.isEnabled, "Second number cannot go below 1")
        for _ in 0..<3 { firstPlus.tap() }
        XCTAssertEqual(equation.label, "39 pluss 1 er 40.", "39 + 1 = 40 is accepted")
        XCTAssertFalse(firstPlus.isEnabled, "39 + 2 = 41 is impossible")
        XCTAssertTrue(app.buttons["workshop.speak"].exists)
    }

    func testWorkshopRespectsLowerLevelCap() {
        launch(level: .start)
        open("workshop")
        let firstPlus = app.buttons["workshop.first.increase"]
        var guardCount = 0
        while firstPlus.isEnabled, guardCount < 20 {
            firstPlus.tap()
            guardCount += 1
        }
        XCTAssertEqual(element("workshop.equation").label, "6 pluss 4 er 10.", "Til 10 caps the total at 10")
    }

    // MARK: Finn tallvennen

    func testPairWrongAnswerKeepsPuzzleActiveAndCorrectAnswerSolves() {
        launch(level: .advanced)
        let solvedBefore = solvedTotalOnHome()
        open("pair")

        // The equation is one accessibility element: "18 pluss hvilket tall er 40".
        let equation = element("pair.equation")
        XCTAssertTrue(equation.waitForExistence(timeout: 5))
        let parts = numbers(in: equation.label)
        XCTAssertEqual(parts.count, 2, "Unsolved equation shows the given number and the target")
        let given = parts[0]
        let target = parts[1]
        let answer = target - given
        XCTAssertTrue(answer >= 1 && answer <= 39, "Missing number \(answer) is positive and below 40")
        XCTAssertTrue(target <= 40, "Target \(target) is at most 40")

        revealGrid(headed: "Velg riktig tall")
        let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pair.choice.'"))
        XCTAssertTrue(choices.element(boundBy: 3).waitForExistence(timeout: 5), "Four choices rendered")
        XCTAssertEqual(choices.count, 4, "Exactly four choices")
        let wrong = (0..<choices.count).map { choices.element(boundBy: $0) }
            .first { numbers(in: $0.identifier).first != answer }
        XCTAssertNotNil(wrong)
        tapScrollingIfNeeded(wrong!)
        let feedback = element("game.feedback")
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.hasPrefix("Prøv igjen."), "Wrong answer invites another try")
        XCTAssertFalse(app.buttons["game.next"].exists, "Puzzle stays active after a wrong answer")

        tapScrollingIfNeeded(app.buttons["pair.choice.\(answer)"])
        XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5), "Correct answer unlocks the next puzzle")
        XCTAssertEqual(feedback.label, "Riktig! \(given) pluss \(answer) er \(target).")
        XCTAssertEqual(equation.label, "\(given) pluss \(answer) er \(target)", "Missing number is revealed")

        tapScrollingIfNeeded(app.buttons["game.next"])
        XCTAssertFalse(app.buttons["game.next"].exists, "A fresh puzzle starts unsolved")

        tapScrollingIfNeeded(app.buttons["game.back"])
        XCTAssertEqual(solvedTotalOnHome(), solvedBefore + 1, "One solved puzzle is counted exactly once")
    }

    // MARK: Del opp

    func testSplitGuidesTowardsTheWantedGroupAndCountsOnce() {
        launch(level: .advanced)
        let solvedBefore = solvedTotalOnHome()
        open("split")

        let total = firstNumber(of: element("split.total"))
        let wanted = firstNumber(of: element("split.wanted"))
        XCTAssertTrue(total >= 5 && total <= 40, "Total \(total) within Til 40")
        XCTAssertTrue(wanted >= 1 && wanted < total, "Wanted \(wanted) keeps both groups non-empty")

        var left = firstNumber(of: element("split.left"))
        let right = firstNumber(of: element("split.right"))
        XCTAssertEqual(left + right, total, "Groups add up to the total")
        XCTAssertNotEqual(left, wanted, "Never starts on the answer")

        tapScrollingIfNeeded(app.buttons["split.check"])
        let feedback = element("game.feedback")
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.contains(left < wanted ? "flere" : "færre"), "Guidance points the right way")
        XCTAssertFalse(app.buttons["game.next"].exists)

        let button = app.buttons[left < wanted ? "split.increase" : "split.decrease"]
        while left != wanted {
            tapScrollingIfNeeded(button)
            left += left < wanted ? 1 : -1
        }
        XCTAssertEqual(firstNumber(of: element("split.left")), wanted)
        XCTAssertEqual(firstNumber(of: element("split.right")), total - wanted)

        tapScrollingIfNeeded(app.buttons["split.check"])
        XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5))
        XCTAssertEqual(feedback.label, "Kjempebra! \(total) er \(wanted) og \(total - wanted) sammen.")
        XCTAssertFalse(app.buttons["split.increase"].isEnabled, "Controls lock after solving")

        tapScrollingIfNeeded(app.buttons["game.back"])
        XCTAssertEqual(solvedTotalOnHome(), solvedBefore + 1)
    }

    // MARK: Bygg tallet

    func testBuildAcceptsTheHintedPairAndRejectsOvershooting() {
        launch(level: .advanced)
        let solvedBefore = solvedTotalOnHome()
        open("build")

        let target = firstNumber(of: element("build.target"))
        XCTAssertTrue(target >= 8 && target <= 40, "Target \(target) within Til 40")

        revealGrid(headed: "Tallbrikker")
        let pieces = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'build.piece.'"))
        XCTAssertTrue(pieces.element(boundBy: 4).waitForExistence(timeout: 5), "Five pieces rendered")
        XCTAssertEqual(pieces.count, 5, "Five pieces are offered")
        let values = (0..<pieces.count).compactMap { numbers(in: pieces.element(boundBy: $0).identifier).first }
        XCTAssertTrue(values.allSatisfy { $0 >= 1 && $0 < target }, "All pieces below target")

        // Ask for a hint and follow it: "Prøv A og B."
        tapScrollingIfNeeded(app.buttons["build.hint"])
        let hint = element("game.feedback")
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        let pair = numbers(in: hint.label)
        XCTAssertEqual(pair.count, 2, "Hint names two pieces")
        XCTAssertEqual(pair[0] + pair[1], target, "Hinted pieces add up to the target")

        tapScrollingIfNeeded(app.buttons["build.piece.\(pair[0])"].firstMatch)
        XCTAssertEqual(firstNumber(of: element("build.currentTotal")), pair[0])
        XCTAssertTrue(app.buttons["build.selected.\(pair[0])"].exists, "Piece moved to the answer area")

        // A piece larger than what is missing must be refused without changing the total.
        // Re-read the live query: the placed piece is no longer offered.
        let remaining = target - pair[0]
        let stillOffered = (0..<pieces.count).compactMap { numbers(in: pieces.element(boundBy: $0).identifier).first }
        if let tooBig = stillOffered.first(where: { $0 > remaining }) {
            tapScrollingIfNeeded(app.buttons["build.piece.\(tooBig)"].firstMatch)
            XCTAssertEqual(firstNumber(of: element("build.currentTotal")), pair[0], "Overshoot rejected")
            XCTAssertEqual(hint.label, "Det blir for mange. Prøv en mindre brikke!")
        }

        tapScrollingIfNeeded(app.buttons["build.piece.\(pair[1])"].firstMatch)
        XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5), "Target reached")
        XCTAssertEqual(firstNumber(of: element("build.currentTotal")), target)
        XCTAssertTrue(hint.label.hasSuffix("er \(target). Bra jobbet!"), "Success feedback names the total")

        tapScrollingIfNeeded(app.buttons["game.back"])
        XCTAssertEqual(solvedTotalOnHome(), solvedBefore + 1)
    }

    // MARK: Talløyene

    /// The simulator keeps the map's stars between runs, so a test that needs a locked second
    /// node clears them first through the Settings control. The Talløyene section sits right
    /// under the level picker, so it is on screen without scrolling the sheet; whether there is
    /// anything to reset is read from the stars sentence (a disabled Form button still reports
    /// itself as enabled).
    private func resetMapProgress() {
        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.navigationBars["Innstillinger"].waitForExistence(timeout: 5))
        let stars = element("settings.mapStars")
        XCTAssertTrue(stars.waitForExistence(timeout: 5), "Map stars sentence in Settings")
        if !stars.label.hasPrefix("Ingen stjerner") {
            let reset = app.buttons["settings.resetMap"]
            XCTAssertTrue(reset.waitForExistence(timeout: 5))
            XCTAssertTrue(reset.isHittable, "Reset control is on screen without scrolling")
            reset.tap()
            let confirm = app.buttons["Nullstill Talløyene"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            confirm.tap()
            // The sentence updates once the dialog has gone; wait for it rather than reading at once.
            let cleared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH 'Ingen stjerner'"), object: stars)
            XCTAssertEqual(XCTWaiter.wait(for: [cleared], timeout: 5), .completed, "Reset clears the stars: \(stars.label)")
        }
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.buttons["home.map"].waitForExistence(timeout: 5))
    }

    /// Solves the bar-building task on screen by tapping bars whose values add up to the target.
    /// The last task of a node is followed by the completion card, which covers the game, so
    /// that call only waits for the card.
    private func solveBarBuildTaskByTapping(expectingCompletion: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        let target = firstNumber(of: element("bar.target"))
        let bars = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'bar.piece.'"))
        XCTAssertTrue(bars.element(boundBy: 3).waitForExistence(timeout: 5), "At least four bars on the shelf", file: file, line: line)
        let values = (0..<bars.count).compactMap { numbers(in: bars.element(boundBy: $0).identifier).first }
        guard let subset = subsetSum(values, target: target) else {
            XCTFail("No bars add up to \(target) among \(values)", file: file, line: line)
            return
        }
        for value in subset {
            tapScrollingIfNeeded(app.buttons["bar.piece.\(value)"].firstMatch)
        }
        if expectingCompletion {
            XCTAssertTrue(app.buttons["challenge.toMap"].waitForExistence(timeout: 8), "Completion card after the last task", file: file, line: line)
        } else {
            XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5), "Task solved", file: file, line: line)
            XCTAssertEqual(firstNumber(of: element("bar.currentTotal")), target, "The zone holds the target", file: file, line: line)
        }
    }

    /// The first subset (in index order) whose values add up to the target.
    private func subsetSum(_ values: [Int], target: Int) -> [Int]? {
        guard !values.isEmpty, values.count <= 12 else { return nil }
        for mask in 1..<(1 << values.count) {
            var sum = 0
            var chosen: [Int] = []
            for index in values.indices where mask & (1 << index) != 0 {
                sum += values[index]
                chosen.append(values[index])
            }
            if sum == target { return chosen }
        }
        return nil
    }

    func testHomeShowsTheMapCardAndTheMapOpens() {
        launch(level: .practice)
        let card = app.buttons["home.map"]
        XCTAssertTrue(card.waitForExistence(timeout: 5), "Map card on the home screen")
        XCTAssertTrue(card.label.hasPrefix("Talløyene"), "Card label: \(card.label)")
        tapScrollingIfNeeded(card)
        XCTAssertTrue(element("map.title").waitForExistence(timeout: 5), "Map title")
        XCTAssertTrue(element("map.stars").label.contains("av 69"), "Star total names the 69 possible stars: \(element("map.stars").label)")
        XCTAssertTrue(app.buttons["map.node.bars-build-5"].waitForExistence(timeout: 5), "First node")
        XCTAssertTrue(app.buttons["map.node.bars-build-5"].isEnabled, "The first node is always open")
        keepScreenshot("Talløyene, portrait, fresh")
        app.buttons["map.back"].tap()
        XCTAssertTrue(app.buttons["home.map"].waitForExistence(timeout: 5), "Back on the home screen")
    }

    func testIslandMapNodeCompletionUnlocksTheNextNodeAndResetLocksItAgain() {
        launch(level: .practice)
        resetMapProgress()
        tapScrollingIfNeeded(app.buttons["home.map"])

        let first = app.buttons["map.node.bars-build-5"]
        let second = app.buttons["map.node.bars-split-6"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.isEnabled, "First node open")
        XCTAssertTrue(second.exists, "Second node drawn")
        XCTAssertFalse(second.isEnabled, "Second node locked before the first is complete")
        XCTAssertTrue(second.label.contains("Låst"), "Locked label: \(second.label)")

        first.tap()
        let progress = element("challenge.progress")
        XCTAssertTrue(progress.waitForExistence(timeout: 5), "Status strip")
        XCTAssertEqual(progress.label, "0 av 4 oppgaver løst")
        XCTAssertEqual(element("challenge.node").label, "Oppgave 1. Bygg med stolper til 5.")

        for task in 0..<4 {
            solveBarBuildTaskByTapping(expectingCompletion: task == 3)
            if task < 3 {
                XCTAssertEqual(progress.label, "\(task + 1) av 4 oppgaver løst")
                tapScrollingIfNeeded(app.buttons["game.next"])
            }
        }
        let toMap = app.buttons["challenge.toMap"]
        XCTAssertTrue(toMap.exists, "Completion card after the fourth task")
        XCTAssertTrue(element("challenge.stars").label.hasPrefix("Du fikk"), "Stars sentence: \(element("challenge.stars").label)")
        keepScreenshot("Completion card after node 1")
        toMap.tap()

        XCTAssertTrue(second.waitForExistence(timeout: 5))
        XCTAssertTrue(second.isEnabled, "Completing node 1 unlocks node 2")
        XCTAssertTrue(first.label.contains("stjerne"), "Node 1 shows its stars: \(first.label)")
        XCTAssertFalse(app.buttons["map.node.bars-build-10"].isEnabled, "Node 3 stays locked")
        keepScreenshot("Talløyene after node 1: stars and an opened padlock")

        // Node 2: cut a bar with the tap alternative (markers) instead of the swipe.
        second.tap()
        XCTAssertTrue(element("bar.target").waitForExistence(timeout: 5))
        let parts = numbers(in: element("bar.target").label)
        XCTAssertEqual(parts.count, 3, "Prompt names the bar and both parts: \(element("bar.target").label)")
        let total = parts[0]
        XCTAssertEqual(parts[1] + parts[2], total, "Parts add up to the bar")
        tapScrollingIfNeeded(app.buttons["bar.piece.\(total)"].firstMatch)
        keepScreenshot("Del stolpen with cut markers")
        tapScrollingIfNeeded(app.buttons["bar.cut.\(parts[1])"])
        let feedback = element("game.feedback")
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(feedback.label.hasSuffix("Kjempebra!"), "Cutting at the wanted place solves the task: \(feedback.label)")
        XCTAssertTrue(app.buttons["game.next"].exists)
        XCTAssertEqual(element("challenge.progress").label, "1 av 4 oppgaver løst")
        tapScrollingIfNeeded(app.buttons["challenge.back"])
        XCTAssertTrue(element("map.title").waitForExistence(timeout: 5), "Back on the map")

        // Reset in Settings locks everything but the first node again.
        app.buttons["map.back"].tap()
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
        resetMapProgress()
        tapScrollingIfNeeded(app.buttons["home.map"])
        XCTAssertTrue(second.waitForExistence(timeout: 5))
        XCTAssertFalse(second.isEnabled, "Reset locks node 2 again")
        XCTAssertTrue(first.isEnabled, "Node 1 stays open")
    }

    /// The four bar nodes of the first island at three stars, pinned through the argument domain
    /// for one launch, so the second island is open without playing the bars first.
    private let firstIslandComplete = ["bars-build-5", "bars-split-6", "bars-build-10", "bars-split-10"]
        .map { "\($0)=3" }
        .joined(separator: ",")

    /// A classic game inside a map node plays at the node's range, whatever level is stored,
    /// shows the status strip instead of its title row, and counts the solved task.
    func testClassicGameInsideAMapNodeKeepsTheNodeRangeAndCountsTheTask() {
        app.launchArguments += ["-islandStars", firstIslandComplete]
        launch(level: .hundred)
        tapScrollingIfNeeded(app.buttons["home.map"])
        let node = app.buttons["map.node.build-20"]
        XCTAssertTrue(node.waitForExistence(timeout: 5), "Node 5 on the map")
        XCTAssertTrue(node.isEnabled, "Open once the first island is complete")
        node.tap()

        let progress = element("challenge.progress")
        XCTAssertTrue(progress.waitForExistence(timeout: 5), "Status strip")
        XCTAssertEqual(progress.label, "0 av 4 oppgaver løst")
        XCTAssertFalse(app.buttons["game.back"].exists, "The strip replaces the title row")
        let target = firstNumber(of: element("build.target"))
        XCTAssertTrue((8...20).contains(target), "Target \(target) within the node's Til 20, not the stored Til 100")

        tapScrollingIfNeeded(app.buttons["build.hint"])
        let pair = numbers(in: element("game.feedback").label)
        XCTAssertEqual(pair.count, 2, "Hint names two pieces: \(element("game.feedback").label)")
        guard pair.count == 2 else { return }
        tapScrollingIfNeeded(app.buttons["build.piece.\(pair[0])"].firstMatch)
        tapScrollingIfNeeded(app.buttons["build.piece.\(pair[1])"].firstMatch)
        XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5), "Task solved")
        XCTAssertEqual(progress.label, "1 av 4 oppgaver løst", "The node counts the solved task")
        keepScreenshot("Bygg tallet inside node 5 after one task")

        tapScrollingIfNeeded(app.buttons["challenge.back"])
        XCTAssertTrue(element("map.title").waitForExistence(timeout: 5), "Back on the map")
    }

    /// Every node of the first four islands at three stars, pinned through the argument domain
    /// for one launch, so a later island is open without playing the whole map.
    private let firstFourIslandsComplete = [
        "bars-build-5", "bars-split-6", "bars-build-10", "bars-split-10", "build-20", "pair-20", "split-20",
        "bars-build-20", "build-40", "pair-40", "split-40", "build-100", "pair-100", "split-100",
    ].map { "\($0)=3" }.joined(separator: ",")

    func testPlaceValueNodeShowsANumberWithBlocksFromTheTray() {
        app.launchArguments += ["-islandStars", firstFourIslandsComplete]
        launch(level: .practice)
        tapScrollingIfNeeded(app.buttons["home.map"])
        let node = app.buttons["map.node.place-show-19"]
        XCTAssertTrue(node.waitForExistence(timeout: 5), "Place-value node on the map")
        XCTAssertTrue(node.isEnabled, "Open once the first four islands are complete")
        node.tap()

        let target = firstNumber(of: element("place.target"))
        XCTAssertTrue((11...19).contains(target), "Teens target \(target)")
        XCTAssertTrue(app.buttons["place.tray.1"].waitForExistence(timeout: 5), "Tens bin")
        tapScrollingIfNeeded(app.buttons["place.tray.1"])
        XCTAssertEqual(firstNumber(of: element("place.number")), 10, "One ten placed")
        for _ in 0..<(target - 10) {
            tapScrollingIfNeeded(app.buttons["place.tray.0"])
        }
        XCTAssertEqual(firstNumber(of: element("place.number")), target, "The blocks show the target")
        XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5), "Task solved")
        XCTAssertTrue(element("game.feedback").label.hasSuffix("Flott!"), "Solved feedback: \(element("game.feedback").label)")
        XCTAssertEqual(element("challenge.progress").label, "1 av 4 oppgaver løst")
        keepScreenshot("Plassverdi: a teen number built from the tray")
        tapScrollingIfNeeded(app.buttons["challenge.back"])
        XCTAssertTrue(element("map.title").waitForExistence(timeout: 5), "Back on the map")
    }

    /// Every node of the first five islands at three stars (see `firstFourIslandsComplete`).
    private var firstFiveIslandsComplete: String {
        firstFourIslandsComplete + "," + [
            "place-show-19", "place-show-99", "place-read-99", "place-away-99", "place-show-999", "place-read-9999",
        ].map { "\($0)=3" }.joined(separator: ",")
    }

    func testBalanceNodeFollowsTheHintsToTheHiddenNumber() {
        // Node 22 opens once node 21 (the first balance board) has stars too.
        app.launchArguments += ["-islandStars", firstFiveIslandsComplete + ",balance-pictures=3"]
        launch(level: .practice)
        tapScrollingIfNeeded(app.buttons["home.map"])
        let node = app.buttons["map.node.balance-hybrid"]
        XCTAssertTrue(node.waitForExistence(timeout: 5), "Balance node on the map")
        XCTAssertTrue(node.isEnabled, "Open once the first five islands and the first balance board are complete")
        node.tap()

        let symbols = element("balance.symbols")
        XCTAssertTrue(symbols.waitForExistence(timeout: 5), "The board is described as a sentence")
        XCTAssertTrue(symbols.label.hasPrefix("knoppen pluss"), "Hybrid board sentence: \(symbols.label)")
        let feedback = element("game.feedback")
        var moves = 0
        while !app.buttons["game.next"].exists, moves < 6 {
            tapScrollingIfNeeded(app.buttons["balance.hint"])
            XCTAssertTrue(feedback.waitForExistence(timeout: 5))
            let words = feedback.label.split(separator: " ").map(String.init)
            XCTAssertEqual(words.first, "Legg", "Hint names a card: \(feedback.label)")
            let polarity = words[1] == "minus" ? "minus" : "plus"
            let value = numbers(in: feedback.label).first ?? 0
            tapScrollingIfNeeded(app.buttons["balance.card.\(polarity).\(value)"])
            moves += 1
        }
        XCTAssertTrue(app.buttons["game.next"].waitForExistence(timeout: 5), "Following the hints opens the bud")
        XCTAssertTrue(feedback.label.hasPrefix("Knoppen åpnet seg"), "Solved feedback: \(feedback.label)")
        XCTAssertEqual(element("balance.stars").label, "3 stjerner", "The shortest solution earns three stars")
        XCTAssertEqual(firstNumber(of: element("balance.moves")), moves, "Move count on screen")
        keepScreenshot("Likevekt: the bud has opened")
        tapScrollingIfNeeded(app.buttons["challenge.back"])
        XCTAssertTrue(element("map.title").waitForExistence(timeout: 5), "Back on the map")
    }

    func testBuildUndoAndRestart() throws {
        launch(level: .practice)
        open("build")
        revealGrid(headed: "Tallbrikker")
        let pieces = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'build.piece.'"))
        XCTAssertTrue(pieces.element(boundBy: 4).waitForExistence(timeout: 5), "Five pieces rendered")
        let smallest = try XCTUnwrap(
            (0..<pieces.count)
                .compactMap { numbers(in: pieces.element(boundBy: $0).identifier).first }
                .min(),
            "At least one piece is offered"
        )
        tapScrollingIfNeeded(app.buttons["build.piece.\(smallest)"].firstMatch)
        XCTAssertEqual(firstNumber(of: element("build.currentTotal")), smallest)

        tapScrollingIfNeeded(app.buttons["build.selected.\(smallest)"])
        XCTAssertEqual(firstNumber(of: element("build.currentTotal")), 0, "Undo removes the piece")
        XCTAssertEqual(pieces.count, 5, "Piece is available again")

        tapScrollingIfNeeded(app.buttons["build.piece.\(smallest)"].firstMatch)
        tapScrollingIfNeeded(app.buttons["build.restart"])
        XCTAssertEqual(firstNumber(of: element("build.currentTotal")), 0, "Restart clears the selection")
    }
}
