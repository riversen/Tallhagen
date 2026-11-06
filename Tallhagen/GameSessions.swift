import Foundation

// Per-activity state machines. They hold everything a game screen needs to decide what to show
// (puzzle, selection, solved flag, feedback) and expose only mutations that keep the
// mathematical contracts in `MathLogic.swift` true. The views in `Games.swift` add layout,
// animation, haptics and speech on top. Foundation only: `Tests/run.sh` compiles this file.

/// What happened after a child's action. Views map this to haptics, speech and the solved counter.
enum AnswerOutcome: Equatable {
    /// The puzzle was completed by this action. Returned exactly once per puzzle.
    case solved
    /// A valid step that did not finish the puzzle.
    case progress
    /// The action was refused (for example a piece that would overshoot). State is unchanged.
    case rejected
    /// A wrong answer. The puzzle stays active and the child can try again.
    case incorrect
    /// Nothing happened: the puzzle was already solved or the action was a no-op.
    case ignored
}

/// Child-facing Norwegian copy produced by the sessions, kept together so a native speaker
/// can review every phrase in one place. Digits stay digits; the iPad voice reads them well.
enum GameCopy {
    static func dots(_ count: Int) -> String {
        count == 1 ? "1 prikk" : "\(count) prikker"
    }

    static func tasksSolved(_ count: Int) -> String {
        count == 1 ? "1 oppgave løst" : "\(count) oppgaver løst"
    }

    /// "3 pluss 4 pluss 5"
    static func plusChain(_ values: [Int]) -> String {
        values.map(String.init).joined(separator: " pluss ")
    }

    /// "3, 4 og 5"
    static func list(_ values: [Int]) -> String {
        guard let last = values.last else { return "" }
        guard values.count > 1 else { return String(last) }
        return values.dropLast().map(String.init).joined(separator: ", ") + " og \(last)"
    }

    // Bygg tallet
    static let buildTooMany = "Det blir for mange. Prøv en mindre brikke!"

    /// When no remaining piece can fit, "try a smaller piece" would be impossible advice,
    /// so the guidance to take a piece back is kept in the same sentence.
    static func buildTooMany(stuck: Bool) -> String {
        stuck ? buildTooMany + " Ingen brikke passer nå. Ta bort en brikke og prøv igjen." : buildTooMany
    }

    static func buildPrompt(target: Int) -> String {
        "Kan du lage \(target)?"
    }

    static func buildProgress(total: Int, remaining: Int, stuck: Bool) -> String {
        var text = "Du har \(total). Du trenger \(remaining) til."
        if stuck {
            text += " Ingen brikke passer nå. Ta bort en brikke og prøv igjen."
        }
        return text
    }

    static func buildSolved(values: [Int], target: Int) -> String {
        "\(plusChain(values)) er \(target). Bra jobbet!"
    }

    static func buildHintPair(_ first: Int, _ second: Int) -> String {
        "Prøv \(first) og \(second)."
    }

    static func buildHintCompletion(_ values: [Int]) -> String {
        if values.count == 1, let value = values.first {
            return "Du trenger \(value) til. Prøv brikken \(value)."
        }
        return "Prøv brikkene \(list(values))."
    }

    static func buildHintStuck(_ first: Int, _ second: Int) -> String {
        "Ingen brikke passer nå. Ta bort en brikke, eller start på nytt med \(first) og \(second)."
    }

    // Finn tallvennen
    static func pairPrompt(given: Int, target: Int) -> String {
        "\(given) pluss hvilket tall er \(target)?"
    }

    static func pairSolved(given: Int, answer: Int, target: Int) -> String {
        "Riktig! \(given) pluss \(answer) er \(target)."
    }

    static func pairIncorrect(given: Int, choice: Int, target: Int) -> String {
        let sum = given + choice
        let direction = sum > target ? "for mye" : "for lite"
        return "Prøv igjen. \(given) pluss \(choice) er \(sum). Det er \(direction). "
            + "Tell hvor mange som mangler til \(target)."
    }

    // Del opp
    static func splitPrompt(total: Int, wantedLeft: Int) -> String {
        splitTotal(total) + " " + splitWanted(wantedLeft)
    }

    static func splitTotal(_ total: Int) -> String {
        "Du har \(dots(total))."
    }

    static func splitWanted(_ wantedLeft: Int) -> String {
        "Lag \(dots(wantedLeft)) til venstre."
    }

    static func splitSolved(total: Int, left: Int, right: Int) -> String {
        "Kjempebra! \(total) er \(left) og \(right) sammen."
    }

    static func splitIncorrect(left: Int, needsMore: Bool) -> String {
        "Du har \(left) til venstre. Du trenger \(needsMore ? "flere" : "færre") prikker til venstre."
    }

    // Menyer
    static let homeMenuIntro = "Velg en lek."
    static let levelChooserIntro = "Hvor store tall vil du leke med?"

    /// "Til 100" spoken as the child hears it in the chooser.
    static func levelChoice(_ level: LearningLevel) -> String {
        level.title
    }

    // Tallstolper
    static func barBuildPrompt(target: Int) -> String {
        "Bygg \(target) med stolpene."
    }

    static func barSplitPrompt(total: Int, parts: [Int]) -> String {
        "Del stolpen \(total) i \(list(parts))."
    }

    static let barTooTall = "Det blir for høyt. Prøv en lavere stolpe!"
    static let barOverTen = "To stolper kan ikke bli høyere enn 10 sammen."

    static func barCombined(_ first: Int, _ second: Int) -> String {
        "\(first) og \(second) ble \(first + second)."
    }

    static func barSplitInto(_ value: Int, _ bottom: Int) -> String {
        "\(value) ble \(bottom) og \(value - bottom)."
    }

    static func barProgress(total: Int, remaining: Int) -> String {
        "Du har \(total). Du trenger \(remaining) til."
    }

    static func barBuildSolved(values: [Int], target: Int) -> String {
        "\(plusChain(values)) er \(target). Bra bygget!"
    }

    static func barSplitSolved(total: Int, parts: [Int]) -> String {
        "\(total) er \(list(parts)). Kjempebra!"
    }

    /// After a cut that does not match the wanted parts: name what is on the shelf and how to go on.
    static func barSplitTryAgain(values: [Int], parts: [Int]) -> String {
        "Du har \(list(values)). Oppgaven er \(list(parts)). Dra stolpene sammen og del på nytt."
    }

    static func barHintParts(_ parts: [Int]) -> String {
        "Prøv \(list(parts))."
    }

    /// Ones are counted rather than listed once there are two or more of them (after many
    /// cuts the shelf may hold a row of ones): "Prøv stolpen 6 og 4 enere.", "Prøv 14 enere.",
    /// and with several other bars the count gets a clause of its own, so it is never heard as
    /// one more bar: "Prøv stolpene 6 og 3, og så 2 enere."
    static func barHintPlace(_ values: [Int]) -> String {
        if values.count == 1, let value = values.first {
            return "Du trenger \(value) til. Prøv stolpen \(value)."
        }
        let ones = values.filter { $0 == 1 }.count
        guard ones >= 2 else { return "Prøv stolpene \(list(values))." }
        let others = values.filter { $0 != 1 }
        switch others.count {
        case 0: return "Prøv \(ones) enere."
        case 1: return "Prøv stolpen \(others[0]) og \(ones) enere."
        default: return "Prøv stolpene \(list(others)), og så \(ones) enere."
        }
    }

    static func barHintSplit(value: Int, bottom: Int) -> String {
        "Del stolpen \(value) i \(bottom) og \(value - bottom)."
    }

    static let barHintSplitGesture = "Stryk sidelengs over stolpen der den skal deles, eller trykk på stolpen og velg et delemerke."

    /// How a built total reads: "1 tierstolpe og 4 enere".
    static func barTotal(_ total: Int) -> String {
        let rods = BarRules.rods(in: total)
        let units = BarRules.units(in: total)
        let rodText = rods == 1 ? "1 tierstolpe" : "\(rods) tierstolper"
        let unitText = units == 1 ? "1 ener" : "\(units) enere"
        if rods == 0 { return unitText }
        if units == 0 { return rodText }
        return rodText + " og " + unitText
    }

    // Talløyene
    static let mapTitle = "Talløyene"
    static let mapIntro = "Velkommen til Talløyene. Trykk på et tall for å begynne."

    static func mapNode(number: Int, title: String) -> String {
        "Oppgave \(number). \(title)."
    }

    static func mapLocked(number: Int) -> String {
        "Låst. Løs oppgave \(number - 1) først."
    }

    static func stars(_ count: Int) -> String {
        switch count {
        case ..<1: return "Ingen stjerner"
        case 1: return "1 stjerne"
        default: return "\(count) stjerner"
        }
    }

    static func challengeProgress(solved: Int, total: Int) -> String {
        "\(solved) av \(total) oppgaver løst"
    }

    static let challengeComplete = "Alle oppgavene er løst!"

    static func challengeResult(stars: Int) -> String {
        "Du fikk \(Self.stars(stars).lowercased())."
    }

    static let challengeToMap = "Tilbake til kartet"
    static let challengeAgain = "Spill igjen"

    // Tallverkstedet
    static let workshopPrompt = "Trykk på pluss og minus for å endre tallene."

    static func workshopInstruction(maximum: Int) -> String {
        "Trykk på pluss og minus for å endre tallene. "
            + "Du kan velge tall fra 1 til \(maximum - 1) og lage summer opp til \(maximum)."
    }

    static func workshopEquation(first: Int, second: Int) -> String {
        "\(first) + \(second) = \(first + second)"
    }

    static func workshopSpoken(first: Int, second: Int) -> String {
        "\(first) pluss \(second) er \(first + second)."
    }
}

// MARK: - Bygg tallet

struct BuildSession {
    let level: LearningLevel
    private(set) var puzzle: BuildPuzzle
    private(set) var selected: [NumberPiece] = []
    private(set) var isSolved = false
    private(set) var feedback: String?

    init(puzzle: BuildPuzzle, level: LearningLevel = .practice) {
        self.puzzle = puzzle
        self.level = level
    }

    init(level: LearningLevel) {
        self.init(puzzle: BuildPuzzle.make(level: level), level: level)
    }

    var target: Int { puzzle.target }
    var currentTotal: Int { selected.reduce(0) { $0 + $1.value } }
    var remaining: Int { target - currentTotal }
    /// The task, as spoken when a puzzle starts or the child asks for it.
    var prompt: String { GameCopy.buildPrompt(target: target) }

    /// Pieces that have not been placed in the answer area, in their shuffled order.
    var availablePieces: [NumberPiece] {
        puzzle.pieces.filter { piece in !isSelected(piece) }
    }

    func isSelected(_ piece: NumberPiece) -> Bool {
        selected.contains { $0.id == piece.id }
    }

    /// Available pieces that would finish the puzzle exactly (fewest first), or nil when stuck.
    var completion: [NumberPiece]? {
        BuildPuzzle.completion(for: remaining, from: availablePieces)
    }

    var canStillComplete: Bool { isSolved || completion != nil }

    /// Adds a piece to the answer area when it fits. Overshooting pieces are refused
    /// without changing the selection; the generated solution pair is never required.
    @discardableResult
    mutating func choose(_ piece: NumberPiece) -> AnswerOutcome {
        guard !isSolved,
              puzzle.pieces.contains(where: { $0.id == piece.id }),
              !isSelected(piece)
        else { return .ignored }

        let newTotal = currentTotal + piece.value
        guard newTotal <= target else {
            feedback = GameCopy.buildTooMany(stuck: !canStillComplete)
            return .rejected
        }

        selected.append(piece)
        if newTotal == target {
            isSolved = true
            feedback = GameCopy.buildSolved(values: selected.map(\.value), target: target)
            return .solved
        }
        feedback = GameCopy.buildProgress(total: newTotal, remaining: remaining, stuck: !canStillComplete)
        return .progress
    }

    /// Drop support: pieces travel as their identifier string.
    @discardableResult
    mutating func choose(pieceID: UUID) -> AnswerOutcome {
        guard let piece = puzzle.pieces.first(where: { $0.id == pieceID }) else { return .ignored }
        return choose(piece)
    }

    /// Takes one selected piece back. Only that piece is removed, even if another has the same value.
    @discardableResult
    mutating func remove(_ piece: NumberPiece) -> Bool {
        guard !isSolved, let index = selected.firstIndex(where: { $0.id == piece.id }) else { return false }
        selected.remove(at: index)
        feedback = selected.isEmpty
            ? nil
            : GameCopy.buildProgress(total: currentTotal, remaining: remaining, stuck: !canStillComplete)
        return true
    }

    mutating func clearSelection() {
        guard !isSolved else { return }
        selected.removeAll()
        feedback = nil
    }

    /// A hint that never contradicts a valid alternative: it completes what the child has
    /// already placed when possible, and otherwise suggests removing a piece.
    /// After completion it simply restates the solved equation.
    var hint: String {
        if isSolved {
            return GameCopy.buildSolved(values: selected.map(\.value), target: target)
        }
        if selected.isEmpty {
            return GameCopy.buildHintPair(puzzle.solution.0, puzzle.solution.1)
        }
        if let completion {
            return GameCopy.buildHintCompletion(completion.map(\.value))
        }
        return GameCopy.buildHintStuck(puzzle.solution.0, puzzle.solution.1)
    }

    mutating func showHint() {
        guard !isSolved else { return }
        feedback = hint
    }
}

// MARK: - Finn tallvennen

struct PairSession {
    let level: LearningLevel
    private(set) var puzzle: PairPuzzle
    private(set) var isSolved = false
    private(set) var feedback: String?
    /// Wrong choices made so far, so the screen can mark them without hiding them.
    private(set) var triedChoices: Set<Int> = []

    init(puzzle: PairPuzzle, level: LearningLevel = .practice) {
        self.puzzle = puzzle
        self.level = level
    }

    init(level: LearningLevel) {
        self.init(puzzle: PairPuzzle.make(level: level), level: level)
    }

    var given: Int { puzzle.given }
    var answer: Int { puzzle.answer }
    var target: Int { puzzle.target }
    var choices: [Int] { puzzle.choices }
    var wrongAttempts: Int { triedChoices.count }
    var prompt: String { GameCopy.pairPrompt(given: given, target: target) }
    /// The equation as one spoken sentence, for VoiceOver and speech.
    var spokenEquation: String {
        isSolved ? "\(given) pluss \(answer) er \(target)" : "\(given) pluss hvilket tall er \(target)"
    }

    @discardableResult
    mutating func answer(_ choice: Int) -> AnswerOutcome {
        guard !isSolved, puzzle.choices.contains(choice) else { return .ignored }
        if choice == puzzle.answer {
            isSolved = true
            feedback = GameCopy.pairSolved(given: given, answer: answer, target: target)
            return .solved
        }
        triedChoices.insert(choice)
        feedback = GameCopy.pairIncorrect(given: given, choice: choice, target: target)
        return .incorrect
    }
}

// MARK: - Del opp

struct SplitSession {
    let level: LearningLevel
    private(set) var puzzle: SplitPuzzle
    private(set) var left: Int
    private(set) var isSolved = false
    private(set) var feedback: String?

    init(puzzle: SplitPuzzle, level: LearningLevel = .practice) {
        self.puzzle = puzzle
        self.level = level
        self.left = puzzle.startingLeft
    }

    init(level: LearningLevel) {
        self.init(puzzle: SplitPuzzle.make(level: level), level: level)
    }

    var total: Int { puzzle.total }
    var right: Int { total - left }
    var wantedLeft: Int { puzzle.wantedLeft }
    var leftRange: ClosedRange<Int> { puzzle.leftRange }
    var prompt: String { GameCopy.splitPrompt(total: total, wantedLeft: wantedLeft) }
    /// The current split as one spoken sentence.
    var spokenState: String { "\(left) til venstre og \(right) til høyre" }
    var canDecrease: Bool { !isSolved && left > leftRange.lowerBound }
    var canIncrease: Bool { !isSolved && left < leftRange.upperBound }

    /// Moves dots between the groups. Values are clamped so neither group is ever empty.
    mutating func setLeft(_ value: Int) {
        guard !isSolved else { return }
        left = min(max(value, leftRange.lowerBound), leftRange.upperBound)
    }

    mutating func decrease() {
        if canDecrease { left -= 1 }
    }

    mutating func increase() {
        if canIncrease { left += 1 }
    }

    @discardableResult
    mutating func check() -> AnswerOutcome {
        guard !isSolved else { return .ignored }
        if left == wantedLeft {
            isSolved = true
            feedback = GameCopy.splitSolved(total: total, left: left, right: right)
            return .solved
        }
        feedback = GameCopy.splitIncorrect(left: left, needsMore: left < wantedLeft)
        return .incorrect
    }
}

// MARK: - Tallverkstedet

struct WorkshopSession {
    private(set) var first: Int
    private(set) var second: Int
    private(set) var maximum: Int

    static let defaultFirst = 3
    static let defaultSecond = 4

    init(maximum: Int) {
        self.maximum = maximum
        self.first = Self.defaultFirst
        self.second = Self.defaultSecond
        clampToMaximum()
    }

    init(level: LearningLevel) {
        self.init(maximum: level.maximum)
    }

    /// Dots per row for this maximum (rows of ten at 100, rows of five below).
    var dotColumns: Int { maximum > 40 ? 10 : 5 }

    var total: Int { first + second }
    var canIncrease: Bool { WorkshopRules.canIncrease(first: first, second: second, maximum: maximum) }
    var canDecreaseFirst: Bool { WorkshopRules.canDecrease(first) }
    var canDecreaseSecond: Bool { WorkshopRules.canDecrease(second) }
    var isValid: Bool { WorkshopRules.isValid(first: first, second: second, maximum: maximum) }
    var equation: String { GameCopy.workshopEquation(first: first, second: second) }
    var spokenEquation: String { GameCopy.workshopSpoken(first: first, second: second) }

    mutating func increaseFirst() { if canIncrease { first += 1 } }
    mutating func increaseSecond() { if canIncrease { second += 1 } }
    mutating func decreaseFirst() { if canDecreaseFirst { first -= 1 } }
    mutating func decreaseSecond() { if canDecreaseSecond { second -= 1 } }

    /// Applies a new level limit, shrinking the larger amount until the total fits again.
    mutating func updateMaximum(_ newMaximum: Int) {
        maximum = newMaximum
        clampToMaximum()
    }

    private mutating func clampToMaximum() {
        first = max(first, 1)
        second = max(second, 1)
        while first + second > maximum, first > 1 || second > 1 {
            if first >= second, first > 1 {
                first -= 1
            } else {
                second -= 1
            }
        }
    }
}

// MARK: - Tallstolper

/// State of one bar task. The shelf holds loose bars; in build mode the building zone holds the
/// placed bars, whose total is shown as tens rods plus a unit bar. Every mutation keeps the
/// `BarRules` true: no bar above ten, no total above the target, no empty part after a cut.
struct BarSession {
    private(set) var puzzle: BarPuzzle
    private(set) var shelf: [NumberPiece]
    private(set) var placed: [NumberPiece] = []
    private(set) var isSolved = false
    private(set) var feedback: String?
    /// The bar made by the last combine (for the squash-and-stretch), or nil.
    private(set) var lastCombined: UUID?
    /// The two bars made by the last cut (for the flash and recoil), or empty.
    private(set) var lastSplit: [UUID] = []

    init(puzzle: BarPuzzle) {
        self.puzzle = puzzle
        self.shelf = puzzle.bars
    }

    init(buildMaximum: Int) {
        self.init(puzzle: BarPuzzle.makeBuild(maximum: buildMaximum))
    }

    init(splitMaximum: Int) {
        self.init(puzzle: BarPuzzle.makeSplit(maximum: splitMaximum))
    }

    var mode: BarPuzzle.Mode { puzzle.mode }
    var target: Int { puzzle.target }
    var wantedParts: [Int] { puzzle.parts }
    var placedTotal: Int { placed.reduce(0) { $0 + $1.value } }
    var remaining: Int { target - placedTotal }
    var rods: Int { BarRules.rods(in: placedTotal) }
    var units: Int { BarRules.units(in: placedTotal) }
    /// True once the child has changed anything (the guide perks up).
    var hasStarted: Bool { !placed.isEmpty || shelf.count != puzzle.bars.count || shelf.map(\.value) != puzzle.bars.map(\.value) }

    var prompt: String {
        switch mode {
        case .build: return GameCopy.barBuildPrompt(target: target)
        case .split: return GameCopy.barSplitPrompt(total: target, parts: wantedParts)
        }
    }

    func shelfPiece(_ id: UUID) -> NumberPiece? {
        shelf.first { $0.id == id }
    }

    /// Merges the moving bar into the one it was dropped on. The result keeps the drop target's
    /// place on the shelf. Refused when the sum would not fit one bar or (build) would exceed
    /// the target, so a combined bar is always placeable.
    @discardableResult
    mutating func combine(_ movingID: UUID, onto targetID: UUID) -> AnswerOutcome {
        guard !isSolved, movingID != targetID,
              let moving = shelfPiece(movingID), let onto = shelfPiece(targetID)
        else { return .ignored }
        let sum = moving.value + onto.value
        guard BarRules.canCombine(moving.value, onto.value) else {
            feedback = GameCopy.barOverTen
            return .rejected
        }
        if mode == .build, sum > remaining {
            feedback = GameCopy.barTooTall
            return .rejected
        }
        let combined = NumberPiece(sum)
        shelf.removeAll { $0.id == movingID }
        if let index = shelf.firstIndex(where: { $0.id == targetID }) {
            shelf[index] = combined
        }
        lastCombined = combined.id
        lastSplit = []
        feedback = GameCopy.barCombined(onto.value, moving.value)
        return checkSplitSolvedOrProgress()
    }

    /// Cuts a shelf bar so that `bottom` units stay in place and the rest becomes a new bar
    /// right after it.
    @discardableResult
    mutating func split(_ id: UUID, bottom: Int) -> AnswerOutcome {
        guard !isSolved, let index = shelf.firstIndex(where: { $0.id == id }) else { return .ignored }
        let value = shelf[index].value
        guard BarRules.canSplit(value, bottom: bottom) else { return .rejected }
        let lower = NumberPiece(bottom)
        let upper = NumberPiece(value - bottom)
        shelf.replaceSubrange(index...index, with: [lower, upper])
        lastSplit = [lower.id, upper.id]
        lastCombined = nil
        feedback = GameCopy.barSplitInto(value, bottom)
        return checkSplitSolvedOrProgress()
    }

    /// Moves a shelf bar into the building zone (build mode). Refused when the total would pass
    /// the target; the shelf is unchanged then.
    @discardableResult
    mutating func place(_ id: UUID) -> AnswerOutcome {
        guard !isSolved, mode == .build, let index = shelf.firstIndex(where: { $0.id == id }) else { return .ignored }
        let piece = shelf[index]
        guard piece.value <= remaining else {
            feedback = GameCopy.barTooTall
            return .rejected
        }
        shelf.remove(at: index)
        placed.append(piece)
        lastCombined = nil
        lastSplit = []
        if remaining == 0 {
            isSolved = true
            feedback = GameCopy.barBuildSolved(values: placed.map(\.value), target: target)
            return .solved
        }
        feedback = GameCopy.barProgress(total: placedTotal, remaining: remaining)
        return .progress
    }

    /// Returns the most recently placed bar to the shelf.
    @discardableResult
    mutating func takeBackLast() -> AnswerOutcome {
        guard !isSolved, mode == .build, let piece = placed.popLast() else { return .ignored }
        shelf.append(piece)
        feedback = placed.isEmpty ? nil : GameCopy.barProgress(total: placedTotal, remaining: remaining)
        return .progress
    }

    /// Split mode: solved when the shelf holds exactly the wanted parts; a wrong two-part cut
    /// is a mistake, anything else is a step.
    private mutating func checkSplitSolvedOrProgress() -> AnswerOutcome {
        guard mode == .split else { return .progress }
        let values = shelf.map(\.value)
        if values.sorted() == wantedParts.sorted() {
            isSolved = true
            feedback = GameCopy.barSplitSolved(total: target, parts: values)
            return .solved
        }
        if values.count == wantedParts.count {
            feedback = GameCopy.barSplitTryAgain(values: values, parts: wantedParts)
            return .incorrect
        }
        return .progress
    }

    /// What the next build hint points at; `hint` turns it into a sentence.
    enum HintStep: Equatable {
        /// Nothing has moved yet: the planned parts, all still on the shelf.
        case parts([Int])
        /// These shelf bars complete the building zone.
        case place([Int])
        /// Cut a shelf bar of `value` so that `bottom` units stay below the cut; that lower
        /// part then completes the zone together with other shelf bars.
        case cut(value: Int, bottom: Int)
        /// Only reachable when the shelf holds less than the remaining amount, which the
        /// generator never produces: the plain state.
        case state
    }

    /// Build mode, unsolved: the step the hint names. Every step can be followed with the bars
    /// on the shelf right now, however many cuts and combines came before; nil otherwise.
    var buildHintStep: HintStep? {
        guard mode == .build, !isSolved else { return nil }
        let values = shelf.map(\.value)
        if placed.isEmpty, values.sorted() == puzzle.bars.map(\.value).sorted() {
            return .parts(wantedParts)
        }
        if let completion = BarRules.fewestBars(adding: remaining, from: values) {
            return .place(completion)
        }
        if let cut = BarRules.cutToComplete(remaining, from: values) {
            return .cut(value: cut.value, bottom: cut.bottom)
        }
        return .state
    }

    /// Honest hints: the partition before anything is placed, the bars that complete the
    /// building zone, or the cut that makes a fitting bar. A build task is always solvable
    /// because the shelf always holds more than the remaining amount and any bar can be cut.
    var hint: String {
        switch mode {
        case .split:
            if isSolved { return GameCopy.barSplitSolved(total: target, parts: wantedParts) }
            if shelf.count == 1 { return GameCopy.barHintSplit(value: target, bottom: wantedParts[0]) + " " + GameCopy.barHintSplitGesture }
            return GameCopy.barSplitTryAgain(values: shelf.map(\.value), parts: wantedParts)
        case .build:
            if isSolved { return GameCopy.barBuildSolved(values: placed.map(\.value), target: target) }
            switch buildHintStep ?? .state {
            case .parts(let parts): return GameCopy.barHintParts(parts)
            case .place(let values): return GameCopy.barHintPlace(values)
            case .cut(let value, let bottom): return GameCopy.barHintSplit(value: value, bottom: bottom)
            case .state: return GameCopy.barProgress(total: placedTotal, remaining: remaining)
            }
        }
    }

    mutating func showHint() {
        guard !isSolved else { return }
        feedback = hint
    }
}

// MARK: - Talløyene

/// Progress through one map node: how many tasks are solved and how many mistakes were made.
/// Complete after `taskCount` solved tasks; further outcomes are ignored.
struct ChallengeRun: Equatable {
    let taskCount: Int
    private(set) var solved = 0
    private(set) var mistakes = 0

    init(taskCount: Int = ChallengeRules.defaultTaskCount) {
        self.taskCount = max(1, taskCount)
    }

    var isComplete: Bool { solved >= taskCount }

    /// 0 until complete, then `ChallengeRules.stars(mistakes:)`.
    var stars: Int { isComplete ? ChallengeRules.stars(mistakes: mistakes) : 0 }

    var progressText: String { GameCopy.challengeProgress(solved: solved, total: taskCount) }

    mutating func record(_ outcome: AnswerOutcome) {
        guard !isComplete else { return }
        switch outcome {
        case .solved: solved += 1
        case .incorrect, .rejected: mistakes += 1
        case .progress, .ignored: break
        }
    }
}

// MARK: - Plassverdi

extension GameCopy {
    static func showPrompt(target: Int) -> String {
        "Vis tallet \(target) med brikkene."
    }

    static let readPrompt = "Hvilket tall viser brikkene?"

    static func takeAwayPrompt(start: Int, amount: Int) -> String {
        "Du har \(start). Ta bort \(amount)."
    }

    /// "1 tusener, 2 hundrere, 4 tiere og 7 enere" (places with zero blocks are left out;
    /// an empty workspace is "ingen brikker").
    static func blocks(_ blocks: PlaceValueBlocks) -> String {
        let parts = PlaceValueUnit.allCases.reversed().compactMap { unit -> String? in
            let count = blocks[unit]
            guard count > 0 else { return nil }
            return "\(count) \(count == 1 ? unit.singular : unit.title)"
        }
        guard !parts.isEmpty else { return "ingen brikker" }
        guard parts.count > 1 else { return parts[0] }
        return parts.dropLast().joined(separator: ", ") + " og \(parts[parts.count - 1])"
    }

    static func showProgress(number: Int, target: Int) -> String {
        "Du har \(number). Du trenger \(target - number) til."
    }

    static let placeTooMuch = "Det blir for mye. Prøv en mindre brikke!"
    static let placeTooLittle = "Da blir det for lite. Legg tilbake en brikke."

    static func regrouped(_ unit: PlaceValueUnit) -> String {
        guard let next = unit.next else { return "" }
        return "Ti \(unit.title) ble én \(next.singular)."
    }

    static func borrowed(_ unit: PlaceValueUnit) -> String {
        guard let lower = unit.previous else { return "" }
        return "Én \(unit.singular) ble ti \(lower.title)."
    }

    static func showSolved(target: Int, blocks: PlaceValueBlocks) -> String {
        "\(Self.blocks(blocks)) er \(target). Flott!"
    }

    static func readSolved(target: Int) -> String {
        "Riktig! Brikkene viser \(target)."
    }

    static let readIncorrect = "Prøv igjen. Tell de største brikkene først, så de små."

    /// The reading hint: what to count, never a "try again" before anything was tried.
    static func readHint(_ blocks: PlaceValueBlocks) -> String {
        "Tell de største brikkene først: \(Self.blocks(blocks))."
    }

    static let takeAwayEnoughOnes = "Du har nok enere. Ta bort enere først."

    static func takeAwayProgress(number: Int, remaining: Int) -> String {
        "Du har \(number). Ta bort \(remaining) til."
    }

    static let takeAwayNeedsBorrow = "Ingen enere igjen. Trykk på en tier for å veksle den i ti enere."

    static func takeAwaySolved(start: Int, amount: Int) -> String {
        "\(start) minus \(amount) er \(start - amount). Kjempebra!"
    }

    static func placeHintAdd(_ unit: PlaceValueUnit, count: Int) -> String {
        "Legg til \(count) \(count == 1 ? unit.singular : unit.title) til."
    }

    static func placeHintRemove(count: Int) -> String {
        "Ta bort \(count) \(count == 1 ? "ener" : "enere") til."
    }
}

/// State of one place-value task. Every mutation keeps the workspace a true picture of its
/// number: adding regroups ten of a place into one of the next, borrowing breaks one block
/// into ten, and nothing can pass the target (show) or drop below the answer (take away).
struct PlaceValueSession {
    private(set) var puzzle: PlaceValuePuzzle
    private(set) var blocks: PlaceValueBlocks
    private(set) var isSolved = false
    private(set) var feedback: String?
    /// Carries made by the last addition (for the carrying animation), per place.
    private(set) var lastCarries: [PlaceValueUnit: Int] = [:]
    /// The place that was broken by the last borrow, or nil.
    private(set) var lastBorrow: PlaceValueUnit?
    /// Take away: the units removed so far, newest last, so a mistake can be undone.
    private(set) var removed: [PlaceValueUnit] = []
    /// Read: wrong choices so far.
    private(set) var triedChoices: Set<Int> = []

    init(puzzle: PlaceValuePuzzle) {
        self.puzzle = puzzle
        switch puzzle.task {
        case .show: blocks = PlaceValueBlocks()
        case .read, .takeAway: blocks = PlaceValueBlocks(number: puzzle.target)
        }
    }

    init(task: PlaceValueTask, level: PlaceValueLevel) {
        self.init(puzzle: PlaceValuePuzzle.make(task: task, level: level))
    }

    var task: PlaceValueTask { puzzle.task }
    var level: PlaceValueLevel { puzzle.level }
    var target: Int { puzzle.target }
    var answer: Int { puzzle.answer }
    var number: Int { blocks.number }
    var choices: [Int] { puzzle.choices }
    /// True once the child has changed the workspace. A wrong reading answer does not count:
    /// the guide never reacts to a wrong answer.
    var hasStarted: Bool { !removed.isEmpty || (task == .show && !blocks.isEmpty) || lastBorrow != nil }

    var prompt: String {
        switch task {
        case .show: return GameCopy.showPrompt(target: target)
        case .read: return GameCopy.readPrompt
        case .takeAway: return GameCopy.takeAwayPrompt(start: target, amount: puzzle.amount)
        }
    }

    /// Show: one more block of `unit` from the tray. Refused when it would pass the target;
    /// otherwise regrouped at once, and solved when the target is reached.
    @discardableResult
    mutating func add(_ unit: PlaceValueUnit) -> AnswerOutcome {
        guard !isSolved, task == .show, level.units.contains(unit) else { return .ignored }
        guard number + unit.value <= target else {
            feedback = GameCopy.placeTooMuch
            return .rejected
        }
        blocks[unit] += 1
        lastBorrow = nil
        lastCarries = blocks.regroup()
        if number == target {
            isSolved = true
            feedback = GameCopy.showSolved(target: target, blocks: blocks)
            return .solved
        }
        if !lastCarries.isEmpty {
            // Every carry is named: ten ones became a ten, and if that made ten tens, a hundred.
            let carries = lastCarries.keys.sorted().map(GameCopy.regrouped).joined(separator: " ")
            feedback = carries + " " + GameCopy.showProgress(number: number, target: target)
        } else {
            feedback = GameCopy.showProgress(number: number, target: target)
        }
        return .progress
    }

    /// Takes one block of `unit` off the workspace. Show: a step back. Take away: refused when
    /// the number would drop below the answer; solved when it reaches it.
    @discardableResult
    mutating func removeOne(_ unit: PlaceValueUnit) -> AnswerOutcome {
        guard !isSolved, task != .read, blocks[unit] > 0 else { return .ignored }
        switch task {
        case .show:
            blocks[unit] -= 1
            lastCarries = [:]
            lastBorrow = nil
            feedback = blocks.isEmpty ? nil : GameCopy.showProgress(number: number, target: target)
            return .progress
        case .takeAway:
            guard number - unit.value >= answer else {
                feedback = GameCopy.placeTooLittle
                return .rejected
            }
            blocks[unit] -= 1
            removed.append(unit)
            lastCarries = [:]
            lastBorrow = nil
            if number == answer {
                isSolved = true
                feedback = GameCopy.takeAwaySolved(start: target, amount: puzzle.amount)
                return .solved
            }
            feedback = blocks[.ones] == 0
                ? GameCopy.takeAwayNeedsBorrow
                : GameCopy.takeAwayProgress(number: number, remaining: number - answer)
            return .progress
        case .read:
            return .ignored
        }
    }

    /// Breaks one block of `unit` into ten of the place below. The number stays the same. In a
    /// take-away task a block is only broken while the ones cannot cover what is left to take
    /// away, so the ones never pile up beyond one broken ten.
    @discardableResult
    mutating func borrow(_ unit: PlaceValueUnit) -> AnswerOutcome {
        guard !isSolved, task != .read, unit.previous != nil, blocks[unit] > 0 else { return .ignored }
        if task == .takeAway, blocks[.ones] >= number - answer {
            feedback = GameCopy.takeAwayEnoughOnes
            return .rejected
        }
        blocks.borrow(from: unit)
        lastCarries = [:]
        lastBorrow = unit
        feedback = GameCopy.borrowed(unit)
        if task == .takeAway {
            feedback! += " " + GameCopy.takeAwayProgress(number: number, remaining: number - answer)
        }
        return .progress
    }

    /// Take away: puts the most recently removed unit back.
    @discardableResult
    mutating func restoreLast() -> AnswerOutcome {
        guard !isSolved, task == .takeAway, let unit = removed.popLast() else { return .ignored }
        blocks[unit] += 1
        lastCarries = [:]
        lastBorrow = nil
        feedback = GameCopy.takeAwayProgress(number: number, remaining: number - answer)
        return .progress
    }

    /// Read: pick a number.
    @discardableResult
    mutating func answer(_ choice: Int) -> AnswerOutcome {
        guard !isSolved, task == .read, choices.contains(choice) else { return .ignored }
        if choice == target {
            isSolved = true
            feedback = GameCopy.readSolved(target: target)
            return .solved
        }
        triedChoices.insert(choice)
        feedback = GameCopy.readIncorrect
        return .incorrect
    }

    /// Honest hints: which blocks are still missing (show), what to count (read), what to take
    /// away or break (take away). After completion the result is restated.
    var hint: String {
        switch task {
        case .show:
            if isSolved { return GameCopy.showSolved(target: target, blocks: blocks) }
            let missing = PlaceValueBlocks(number: target - number)
            if let unit = PlaceValueUnit.allCases.reversed().first(where: { missing[$0] > 0 }) {
                return GameCopy.placeHintAdd(unit, count: missing[unit])
            }
            return GameCopy.showProgress(number: number, target: target)
        case .read:
            if isSolved { return GameCopy.readSolved(target: target) }
            return GameCopy.readHint(blocks)
        case .takeAway:
            if isSolved { return GameCopy.takeAwaySolved(start: target, amount: puzzle.amount) }
            if blocks[.ones] == 0 { return GameCopy.takeAwayNeedsBorrow }
            return GameCopy.placeHintRemove(count: number - answer)
        }
    }

    mutating func showHint() {
        guard !isSolved else { return }
        feedback = hint
    }
}

// MARK: - Likevekt

extension GameCopy {
    /// What to do, shown in the task panel and spoken with the question: the bud opens when it
    /// stands alone.
    static func balanceGoal(coefficient: Int) -> String {
        coefficient == 1
            ? "Legg samme kort på begge sider til knoppen står alene."
            : "Legg samme kort på begge sider, eller del begge sidene likt, til én knopp står alene."
    }

    /// The task, for one bud or several (each bud hides the same number).
    static func balancePrompt(coefficient: Int) -> String {
        let question = coefficient == 1
            ? "Hva gjemmer seg i knoppen?"
            : "Hva gjemmer seg i knoppene? Hver knopp gjemmer det samme tallet."
        return question + " " + balanceGoal(coefficient: coefficient)
    }

    /// "knoppen pluss 3 er 7", "2 knopper pluss 3 er 11" — the board as a sentence.
    static func balanceEquation(coefficient: Int, left: Int, right: Int) -> String {
        var leftPart = coefficient == 1 ? "knoppen" : "\(coefficient) knopper"
        if left > 0 {
            leftPart += " pluss \(left)"
        }
        return "\(leftPart) er \(right)"
    }

    /// Symbols for the top of the board: "? + 3 = 7", "2 · ? = 8".
    static func balanceSymbols(coefficient: Int, left: Int, right: Int) -> String {
        var leftPart = coefficient == 1 ? "?" : "\(coefficient) · ?"
        if left > 0 {
            leftPart += " + \(left)"
        }
        return "\(leftPart) = \(right)"
    }

    static func balanceAdded(value: Int, inverse: Bool) -> String {
        "Du la \(inverse ? "minus" : "pluss") \(value) på begge sider."
    }

    static func balanceCancelled(_ value: Int) -> String {
        "\(value) og minus \(value) ble null."
    }

    static func balanceExchanged(_ value: Int, into parts: [Int]) -> String {
        "\(value) ble \(list(parts))."
    }

    static func balanceDivided(by divisor: Int) -> String {
        "Begge sidene ble delt i \(divisor) like deler."
    }

    /// A division that does not work yet: the left amount cannot be split into equal parts.
    static func balanceCannotDivide(left: Int, divisor: Int) -> String {
        "\(left) kan ikke deles i \(divisor) like deler. Legg kort på begge sider først."
    }

    /// An inverse card bigger than the amount beside the buds.
    static func balanceTooMuchAway(left: Int, coefficient: Int) -> String {
        let buds = coefficient == 1 ? "knoppen" : "knoppene"
        return left == 0
            ? "Det er ingenting å ta bort ved siden av \(buds)."
            : "Ved siden av \(buds) er det bare \(left). Prøv et mindre minuskort."
    }

    /// A card that would put more on a side than the board holds.
    static let balanceTooFull = "Så mye får ikke plass på vekten. Prøv et mindre kort."

    static let balanceGathered = "Kortene ble samlet til færre kort."

    static func balanceSolved(unknown: Int, moves: Int) -> String {
        "Knoppen åpnet seg: tallet er \(unknown)! Du brukte \(Self.moves(moves))."
    }

    static func balanceHintAdd(value: Int, inverse: Bool) -> String {
        "Legg \(inverse ? "minus" : "pluss") \(value) på begge sider."
    }

    static func balanceHintDivide(by divisor: Int) -> String {
        "Del begge sidene i \(divisor) like deler."
    }

    static func moves(_ count: Int) -> String {
        count == 1 ? "1 trekk" : "\(count) trekk"
    }
}

/// State of one balance board. The invariant never breaks: `coefficient` hidden numbers plus
/// the left amount always equal the right amount, because every card is mirrored on the other
/// side and every division divides both sides. Both sides hold positive cards only: an inverse
/// card cancels at once against the cards it meets (changing a bigger card into smaller ones
/// when only part of it is taken), and it is refused when the left side holds less than it.
/// Cards keep their identities, so the view can show the mirror and the cancelling pair.
struct BalanceSession {
    /// What the last move did, for the animations.
    struct MoveEffect: Equatable {
        /// The card the move put on each side (the right one is the mirror).
        var leftCard: BalanceCard?
        var rightCard: BalanceCard?
        /// Cards that left each side because an inverse card took them away.
        var takenLeft: [BalanceCard] = []
        var takenRight: [BalanceCard] = []
        var divisor: Int?
    }

    private(set) var puzzle: BalancePuzzle
    private(set) var coefficient: Int
    private(set) var leftCards: [BalanceCard]
    private(set) var rightCards: [BalanceCard]
    private(set) var moves = 0
    private(set) var isSolved = false
    private(set) var feedback: String?
    private(set) var lastEffect: MoveEffect?

    init(puzzle: BalancePuzzle) {
        self.puzzle = puzzle
        coefficient = puzzle.coefficient
        leftCards = BalanceRules.cards(for: puzzle.leftConstant)
        rightCards = BalanceRules.cards(for: puzzle.rightConstant)
    }

    init(phase: BalancePhase) {
        self.init(puzzle: BalancePuzzle.make(phase: phase))
    }

    var phase: BalancePhase { puzzle.phase }
    var unknown: Int { puzzle.unknown }
    var optimalMoves: Int { puzzle.optimalMoves }
    var left: Int { leftCards.reduce(0) { $0 + $1.signedValue } }
    var right: Int { rightCards.reduce(0) { $0 + $1.signedValue } }
    var isBalanced: Bool { BalanceRules.isBalanced(unknown: unknown, coefficient: coefficient, left: left, right: right) }
    var hasStarted: Bool { moves > 0 }
    var stars: Int { isSolved ? BalanceRules.stars(moves: moves, optimal: optimalMoves) : 0 }
    var equation: String { GameCopy.balanceEquation(coefficient: coefficient, left: left, right: right) }
    var symbols: String { GameCopy.balanceSymbols(coefficient: coefficient, left: left, right: right) }

    var prompt: String {
        GameCopy.balancePrompt(coefficient: puzzle.coefficient)
    }

    var goal: String {
        GameCopy.balanceGoal(coefficient: puzzle.coefficient)
    }

    /// The most cards a side keeps; more are gathered into the fewest cards for the same amount
    /// (at most five for the board's maximum), so the trays keep their height.
    static let maximumCardsPerSide = 5

    /// The division the rail offers: the number of hidden numbers on the board, while there are
    /// two or three of them. Only boards that start with more than one hidden number have a rail.
    var availableDivisors: [Int] {
        coefficient > 1 ? [coefficient] : []
    }

    /// Puts a card on the left and its mirror on the right. An inverse card takes its amount
    /// away from the cards on each side. Refused (and not counted) when the left side holds
    /// less than an inverse card, or when a side would pass the board's maximum.
    @discardableResult
    mutating func add(value: Int, inverse: Bool) -> AnswerOutcome {
        guard !isSolved, BalanceRules.cardValues.contains(value) else { return .ignored }
        guard BalanceRules.apply(.add(value: value, inverse: inverse), coefficient: coefficient, left: left, right: right, maximum: puzzle.maximum) != nil else {
            feedback = inverse ? GameCopy.balanceTooMuchAway(left: left, coefficient: coefficient) : GameCopy.balanceTooFull
            return .rejected
        }
        let card = BalanceCard(value: value, isInverse: inverse)
        let mirror = BalanceCard(value: value, isInverse: inverse)
        var effect = MoveEffect(leftCard: card, rightCard: mirror)
        var sentence = GameCopy.balanceAdded(value: value, inverse: inverse)
        if inverse {
            let leftChange = Self.takeAway(value, from: &leftCards)
            let rightChange = Self.takeAway(value, from: &rightCards)
            effect.takenLeft = leftChange.taken
            effect.takenRight = rightChange.taken
            if let exchange = leftChange.exchange {
                sentence += " " + GameCopy.balanceExchanged(exchange.value, into: exchange.parts)
            }
            sentence += " " + GameCopy.balanceCancelled(value)
        } else {
            leftCards.append(card)
            rightCards.append(mirror)
        }
        let gatheredLeft = Self.gather(&leftCards)
        let gatheredRight = Self.gather(&rightCards)
        if gatheredLeft || gatheredRight {
            sentence += " " + GameCopy.balanceGathered
        }
        moves += 1
        lastEffect = effect
        return finishMove(sentence)
    }

    /// Replaces a side's cards by the fewest cards for the same amount when it holds more than
    /// `maximumCardsPerSide`. Returns whether it did.
    private static func gather(_ cards: inout [BalanceCard]) -> Bool {
        guard cards.count > maximumCardsPerSide else { return false }
        cards = BalanceRules.cards(for: cards.reduce(0) { $0 + $1.signedValue })
        return true
    }

    /// Splits both sides into `divisor` equal parts: the number of hidden numbers and both
    /// amounts. Refused (and not counted) while the left amount cannot be split evenly.
    @discardableResult
    mutating func divide(by divisor: Int) -> AnswerOutcome {
        guard !isSolved, availableDivisors.contains(divisor) else { return .ignored }
        guard let next = BalanceRules.apply(.divide(by: divisor), coefficient: coefficient, left: left, right: right, maximum: puzzle.maximum) else {
            feedback = GameCopy.balanceCannotDivide(left: left, divisor: divisor)
            return .rejected
        }
        coefficient = next.coefficient
        leftCards = BalanceRules.cards(for: next.left)
        rightCards = BalanceRules.cards(for: next.right)
        moves += 1
        lastEffect = MoveEffect(divisor: divisor)
        return finishMove(GameCopy.balanceDivided(by: divisor))
    }

    private mutating func finishMove(_ sentence: String) -> AnswerOutcome {
        if coefficient == 1, left == 0 {
            isSolved = true
            feedback = GameCopy.balanceSolved(unknown: unknown, moves: moves)
            return .solved
        }
        feedback = sentence
        return .progress
    }

    /// Takes `amount` off a side's cards so that the sentence tells exactly what the child sees:
    /// one card of that amount if there is one; otherwise whole cards that add up to it (biggest
    /// first); otherwise the smallest card bigger than the amount is changed, the amount goes and
    /// the rest stays (5 with 2 to take: "5 ble 2, 2 og 1", and one 2 goes); only when every card
    /// is smaller, whole cards go and the last one needed is changed (2, 2 and 2 with 5 to take:
    /// two 2s go and the third becomes 1 and 1). Returns the cards that left the side and the
    /// change, if any. The side always holds at least `amount` (an inverse card bigger than the
    /// left side is refused, and the right side always holds at least as much as the left).
    private static func takeAway(_ amount: Int, from cards: inout [BalanceCard]) -> (taken: [BalanceCard], exchange: (value: Int, parts: [Int])?) {
        if let index = cards.firstIndex(where: { $0.value == amount }) {
            return ([cards.remove(at: index)], nil)
        }
        func takeWholeCards(_ amount: Int, from cards: inout [BalanceCard]) -> (taken: [BalanceCard], remaining: Int) {
            var remaining = amount
            var taken: [BalanceCard] = []
            while remaining > 0, let index = cards.indices.filter({ cards[$0].value <= remaining }).max(by: { cards[$0].value < cards[$1].value }) {
                remaining -= cards[index].value
                taken.append(cards.remove(at: index))
            }
            return (taken, remaining)
        }
        var trial = cards
        let whole = takeWholeCards(amount, from: &trial)
        if whole.remaining == 0 {
            cards = trial
            return (whole.taken, nil)
        }
        if let index = cards.indices.filter({ cards[$0].value > amount }).min(by: { cards[$0].value < cards[$1].value }) {
            let big = cards.remove(at: index)
            let stays = BalanceRules.cards(for: big.value - amount)
            cards.insert(contentsOf: stays, at: index)
            return ([big], (big.value, ([amount] + stays.map(\.value)).sorted(by: >)))
        }
        var taken = takeWholeCards(amount, from: &cards)
        guard taken.remaining > 0, let index = cards.indices.min(by: { cards[$0].value < cards[$1].value }) else {
            return (taken.taken, nil)
        }
        let last = cards.remove(at: index)
        let stays = BalanceRules.cards(for: last.value - taken.remaining)
        cards.insert(contentsOf: stays, at: index)
        taken.taken.append(last)
        return (taken.taken, (last.value, ([taken.remaining] + stays.map(\.value)).sorted(by: >)))
    }

    /// What the node's rating hears about an outcome: a refused card or division costs nothing,
    /// and a solved board counts one mistake for every star it missed (like a mistake in the
    /// other activities), then the solve.
    func challengeReports(for outcome: AnswerOutcome) -> [AnswerOutcome] {
        switch outcome {
        case .ignored, .rejected:
            return []
        case .solved:
            return Array(repeating: .incorrect, count: max(0, ChallengeRules.maximumStars - stars)) + [.solved]
        case .progress, .incorrect:
            return [outcome]
        }
    }

    /// The next step of a shortest solution from the board as it is now.
    var nextMove: BalanceMove? {
        guard !isSolved else { return nil }
        return BalanceRules.shortestSolution(coefficient: coefficient, left: left, right: right, maximum: puzzle.maximum)?.first
    }

    /// Honest hints: the first step of a shortest solution from here.
    var hint: String {
        if isSolved { return GameCopy.balanceSolved(unknown: unknown, moves: moves) }
        switch nextMove {
        case .add(let value, let inverse)?: return GameCopy.balanceHintAdd(value: value, inverse: inverse)
        case .divide(let divisor)?: return GameCopy.balanceHintDivide(by: divisor)
        case nil: return prompt
        }
    }

    mutating func showHint() {
        guard !isSolved else { return }
        feedback = hint
    }
}
