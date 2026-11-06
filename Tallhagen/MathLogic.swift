import Foundation

// All educational puzzle generation lives here and can be tested without SwiftUI.
// This file imports only Foundation so `Tests/run.sh` can compile it with plain `swiftc`
// on macOS or Linux. Keep SwiftUI, UIKit and persistence out of it.

enum LearningLevel: Int, CaseIterable, Identifiable {
    case start = 1
    case practice = 2
    case challenge = 3
    case advanced = 4
    case hundred = 5

    /// The three ranges a child picks from before starting (Til 20, Til 40, Til 100).
    /// The other levels stay available in Settings and keep their stored identifiers.
    static let starterChoices: [LearningLevel] = [.practice, .advanced, .hundred]

    /// The level used when nothing has been stored yet or the stored value is unknown.
    static let fallback: LearningLevel = .practice

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .start: return "Til 10"
        case .practice: return "Til 20"
        case .challenge: return "Til 30"
        case .advanced: return "Til 40"
        case .hundred: return "Til 100"
        }
    }

    var detail: String {
        switch self {
        case .start: return "Passer for å komme i gang"
        case .practice: return "Tallvenner og pluss til 20"
        case .challenge: return "Litt større tall"
        case .advanced: return "Utforsk tall og mengder til 40"
        case .hundred: return "Store tall helt til 100"
        }
    }

    /// The largest number a task sets at this level (targets, pieces, choices, totals). Feedback
    /// on a wrong answer in Finn tallvennen still states the real sum, which can be larger.
    var maximum: Int {
        switch self {
        case .start: return 10
        case .practice: return 20
        case .challenge: return 30
        case .advanced: return 40
        case .hundred: return 100
        }
    }

    /// Dots per row in every dot frame at this level: rows of five up to 40, rows of ten at 100,
    /// so each level reads consistently and 100 is ten rows of ten.
    var dotColumns: Int {
        maximum > 40 ? 10 : 5
    }

    /// Resolves a persisted raw value. Unknown values fall back to `.practice`
    /// so an old or corrupted preference never crashes the app or changes level meanings.
    static func resolve(_ rawValue: Int) -> LearningLevel {
        LearningLevel(rawValue: rawValue) ?? fallback
    }
}

/// One positive integer with its own identity, so two pieces with the same value
/// can be told apart when a child selects or removes one of them.
struct NumberPiece: Identifiable, Equatable {
    let id: UUID
    let value: Int

    init(_ value: Int) {
        self.id = UUID()
        self.value = value
    }
}

// MARK: - Bygg tallet

struct BuildPuzzle {
    let target: Int
    /// A guaranteed pair of positive pieces that sums to the target.
    /// It is one valid answer, not the only one: any selection with the right sum counts.
    let solution: (Int, Int)
    /// Exactly five pieces: the solution pair plus three distractors, all below the target.
    let pieces: [NumberPiece]

    /// Targets start at 5 for the first level and at 8 for the others, up to the level maximum.
    static func targetRange(for level: LearningLevel) -> ClosedRange<Int> {
        (level == .start ? 5 : 8)...level.maximum
    }

    static func make(level: LearningLevel, target requestedTarget: Int? = nil) -> BuildPuzzle {
        var generator = SystemRandomNumberGenerator()
        return make(level: level, target: requestedTarget, using: &generator)
    }

    /// Generates a puzzle with an explicit random source, so tests can reproduce a run.
    /// `requestedTarget` exists for deterministic tests and must lie inside the level's range.
    static func make<G: RandomNumberGenerator>(
        level: LearningLevel,
        target requestedTarget: Int? = nil,
        using generator: inout G
    ) -> BuildPuzzle {
        let range = targetRange(for: level)
        let target = requestedTarget ?? Int.random(in: range, using: &generator)
        precondition(range.contains(target), "Target outside selected level")
        let first = Int.random(in: 1..<target, using: &generator)
        let second = target - first
        var values = [first, second]
        // Extra pieces encourage experimentation. A correct alternative sum also counts.
        for _ in 0..<3 {
            values.append(Int.random(in: 1..<target, using: &generator))
        }
        return BuildPuzzle(
            target: target,
            solution: (first, second),
            pieces: values.shuffled(using: &generator).map(NumberPiece.init)
        )
    }

    /// Finds pieces among `candidates` whose values add up exactly to `amount`.
    /// Prefers the fewest pieces; returns nil when no combination fits.
    /// Candidates are at most a handful of pieces, so an exhaustive search is instant.
    static func completion(for amount: Int, from candidates: [NumberPiece]) -> [NumberPiece]? {
        guard amount > 0, !candidates.isEmpty else { return nil }
        precondition(candidates.count <= 12, "Completion search is meant for a few pieces")
        var best: [NumberPiece]?
        for mask in 1..<(1 << candidates.count) {
            var sum = 0
            var subset: [NumberPiece] = []
            for index in candidates.indices where mask & (1 << index) != 0 {
                sum += candidates[index].value
                subset.append(candidates[index])
            }
            if sum == amount, best == nil || subset.count < best!.count {
                best = subset
            }
        }
        return best
    }
}

// MARK: - Finn tallvennen

struct PairPuzzle {
    let target: Int
    let given: Int
    let answer: Int
    /// Four distinct positive choices below the target; exactly one equals `answer`.
    let choices: [Int]

    static func targetRange(for level: LearningLevel) -> ClosedRange<Int> {
        5...level.maximum
    }

    static func make(level: LearningLevel, target requestedTarget: Int? = nil) -> PairPuzzle {
        var generator = SystemRandomNumberGenerator()
        return make(level: level, target: requestedTarget, using: &generator)
    }

    static func make<G: RandomNumberGenerator>(
        level: LearningLevel,
        target requestedTarget: Int? = nil,
        using generator: inout G
    ) -> PairPuzzle {
        let range = targetRange(for: level)
        let target = requestedTarget ?? Int.random(in: range, using: &generator)
        precondition(range.contains(target), "Target outside selected level")
        let given = Int.random(in: 1..<target, using: &generator)
        let answer = target - given
        // Ordered on purpose: a Set would iterate in a per-instance order and break seeded
        // reproducibility. A target of at least 5 guarantees four distinct values in 1..<target.
        var options = [answer]
        while options.count < 4 {
            let candidate = Int.random(in: 1..<target, using: &generator)
            if !options.contains(candidate) {
                options.append(candidate)
            }
        }
        return PairPuzzle(
            target: target,
            given: given,
            answer: answer,
            choices: options.shuffled(using: &generator)
        )
    }
}

// MARK: - Del opp

struct SplitPuzzle {
    let total: Int
    let wantedLeft: Int

    var wantedRight: Int { total - wantedLeft }

    /// Both groups must stay non-empty, so the left count lives in this range.
    var leftRange: ClosedRange<Int> { 1...(total - 1) }

    /// Where the slider starts: near the middle, but never already on the wanted answer,
    /// so the child always has to move something before checking.
    var startingLeft: Int {
        let half = max(1, min(total - 1, total / 2))
        if half != wantedLeft { return half }
        return half < total - 1 ? half + 1 : half - 1
    }

    static func totalRange(for level: LearningLevel) -> ClosedRange<Int> {
        5...level.maximum
    }

    static func make(level: LearningLevel, total requestedTotal: Int? = nil) -> SplitPuzzle {
        var generator = SystemRandomNumberGenerator()
        return make(level: level, total: requestedTotal, using: &generator)
    }

    static func make<G: RandomNumberGenerator>(
        level: LearningLevel,
        total requestedTotal: Int? = nil,
        using generator: inout G
    ) -> SplitPuzzle {
        let range = totalRange(for: level)
        let total = requestedTotal ?? Int.random(in: range, using: &generator)
        precondition(range.contains(total), "Total outside selected level")
        let left = Int.random(in: 1..<total, using: &generator)
        return SplitPuzzle(total: total, wantedLeft: left)
    }
}

// MARK: - Tallverkstedet

/// Pure workshop rules make the 40-point limit easy to test independently of SwiftUI.
enum WorkshopRules {
    static func isValid(first: Int, second: Int, maximum: Int) -> Bool {
        first >= 1 && second >= 1 && first + second <= maximum
    }

    static func canIncrease(first: Int, second: Int, maximum: Int) -> Bool {
        isValid(first: first, second: second, maximum: maximum)
            && first + second < maximum
    }

    static func canDecrease(_ value: Int) -> Bool {
        value > 1
    }
}

// MARK: - Tallstolper (number bars 1–10)

/// Rules for the number bars: a bar holds one to ten units, two bars combine only while their
/// sum still fits one bar, a split always leaves two positive parts, and a built total above
/// ten is shown as tens rods plus a unit bar.
enum BarRules {
    static let maximumBarValue = 10

    static func isValidBar(_ value: Int) -> Bool {
        (1...maximumBarValue).contains(value)
    }

    static func canCombine(_ first: Int, _ second: Int) -> Bool {
        isValidBar(first) && isValidBar(second) && first + second <= maximumBarValue
    }

    /// A bar of `value` can be cut so that `bottom` units stay below the cut.
    static func canSplit(_ value: Int, bottom: Int) -> Bool {
        isValidBar(value) && bottom >= 1 && bottom < value
    }

    /// Full tens rods in a built total (14 → 1).
    static func rods(in total: Int) -> Int {
        max(0, total) / maximumBarValue
    }

    /// Units left beside the rods (14 → 4).
    static func units(in total: Int) -> Int {
        max(0, total) % maximumBarValue
    }

    /// Opacity of the white numeral drawn on a bar for a node whose biggest total is `maximum`:
    /// hidden while the child builds to 5 (count the units), then stronger with the range and
    /// fully opaque from 20 upward. Never decreases with the range.
    static func numeralOpacity(forMaximum maximum: Int) -> Double {
        switch maximum {
        case ..<6: return 0
        case ..<11: return 0.55
        case ..<20: return 0.8
        default: return 1
        }
    }

    /// The fewest bars among `values` that add up to exactly `amount`, largest first, or nil.
    /// Ties go to the larger bars. Searches value counts (at most ten distinct values), so it
    /// stays instant however many bars cutting has put on the shelf.
    static func fewestBars(adding amount: Int, from values: [Int]) -> [Int]? {
        guard amount > 0 else { return nil }
        var counts: [Int: Int] = [:]
        for value in values where value > 0 {
            counts[value, default: 0] += 1
        }
        let distinct = counts.keys.sorted(by: >)
        var best: [Int]?
        var chosen: [Int] = []
        // Depth first, larger values and more of them first: the first complete choice of a
        // given size is the one with the largest bars.
        func search(_ index: Int, _ left: Int) {
            if left == 0 {
                if best == nil || chosen.count < best!.count { best = chosen }
                return
            }
            guard index < distinct.count else { return }
            if let best, chosen.count + 1 >= best.count { return }
            let value = distinct[index]
            let most = min(counts[value] ?? 0, left / value)
            for take in stride(from: most, through: 0, by: -1) {
                chosen.append(contentsOf: repeatElement(value, count: take))
                search(index + 1, left - take * value)
                chosen.removeLast(take)
            }
        }
        search(0, amount)
        return best
    }

    /// The one cut after which `fewestBars(adding: amount, …)` succeeds with the fewest bars:
    /// cut a bar of `value` so that `bottom` units stay below the cut, then use that lower part.
    /// Ties go to the smaller bar and the larger lower part. Nil when no single cut helps,
    /// which never happens while the bars add up to at least `amount`.
    static func cutToComplete(_ amount: Int, from values: [Int]) -> (value: Int, bottom: Int)? {
        guard amount > 0 else { return nil }
        var best: (value: Int, bottom: Int, bars: Int)?
        for value in Set(values).sorted() where value > 1 {
            var rest = values
            if let index = rest.firstIndex(of: value) { rest.remove(at: index) }
            for bottom in stride(from: min(value - 1, amount), through: 1, by: -1) {
                let needed = amount - bottom
                let bars: Int
                if needed == 0 {
                    bars = 1
                } else if let others = fewestBars(adding: needed, from: rest) {
                    bars = others.count + 1
                } else {
                    continue
                }
                if best == nil || bars < best!.bars {
                    best = (value, bottom, bars)
                }
            }
        }
        return best.map { (value: $0.value, bottom: $0.bottom) }
    }
}

/// One bar task. Build: drag bars into the building zone until the total equals `target`
/// (bars may be combined or split on the shelf first). Split: cut the single bar `target`
/// into the two `parts`, in either order.
struct BarPuzzle {
    enum Mode: Equatable {
        case build
        case split
    }

    let mode: Mode
    /// Build: the total to build. Split: the value of the bar to cut.
    let target: Int
    /// Build: one guaranteed partition of the target among the shelf bars. Split: the wanted parts.
    let parts: [Int]
    /// Bars on the shelf when the task starts.
    let bars: [NumberPiece]

    /// Targets for a build node: 2…maximum up to ten; above ten the last ten values, so every
    /// task of a node to 20 needs a tens rod.
    static func buildTargetRange(maximum: Int) -> ClosedRange<Int> {
        let top = max(2, maximum)
        return top <= BarRules.maximumBarValue ? 2...top : (top - 9)...top
    }

    /// Totals for a split node: 2…maximum, never above one bar.
    static func splitTotalRange(maximum: Int) -> ClosedRange<Int> {
        2...max(2, min(maximum, BarRules.maximumBarValue))
    }

    static func makeBuild(maximum: Int, target requestedTarget: Int? = nil) -> BarPuzzle {
        var generator = SystemRandomNumberGenerator()
        return makeBuild(maximum: maximum, target: requestedTarget, using: &generator)
    }

    /// Two parts for small targets, three from 7 upward; every part fits one bar. Two extra
    /// bars (never equal to or above the target) invite combining and splitting.
    static func makeBuild<G: RandomNumberGenerator>(
        maximum: Int,
        target requestedTarget: Int? = nil,
        using generator: inout G
    ) -> BarPuzzle {
        let range = buildTargetRange(maximum: maximum)
        let target = requestedTarget ?? Int.random(in: range, using: &generator)
        precondition(range.contains(target), "Bar target outside the node's range")
        let cap = BarRules.maximumBarValue
        var parts: [Int]
        if target <= 6 {
            let first = Int.random(in: 1..<target, using: &generator)
            parts = [first, target - first]
        } else {
            // Three positive parts, each at most one bar.
            let first = Int.random(in: max(1, target - 2 * cap)...min(cap, target - 2), using: &generator)
            let rest = target - first
            let second = Int.random(in: max(1, rest - cap)...min(cap, rest - 1), using: &generator)
            parts = [first, second, rest - second]
        }
        var values = parts
        let distractorTop = min(cap, target - 1)
        for _ in 0..<2 {
            values.append(Int.random(in: 1...distractorTop, using: &generator))
        }
        return BarPuzzle(
            mode: .build,
            target: target,
            parts: parts,
            bars: values.shuffled(using: &generator).map(NumberPiece.init)
        )
    }

    static func makeSplit(maximum: Int, total requestedTotal: Int? = nil) -> BarPuzzle {
        var generator = SystemRandomNumberGenerator()
        return makeSplit(maximum: maximum, total: requestedTotal, using: &generator)
    }

    static func makeSplit<G: RandomNumberGenerator>(
        maximum: Int,
        total requestedTotal: Int? = nil,
        using generator: inout G
    ) -> BarPuzzle {
        let range = splitTotalRange(maximum: maximum)
        let total = requestedTotal ?? Int.random(in: range, using: &generator)
        precondition(range.contains(total), "Bar total outside the node's range")
        let bottom = Int.random(in: 1..<total, using: &generator)
        return BarPuzzle(mode: .split, target: total, parts: [bottom, total - bottom], bars: [NumberPiece(total)])
    }
}

// MARK: - Talløyene (the island map)

/// The guide creature that hosts an island. Mirrors `GardenCreature` without importing SwiftUI.
enum MapGuide: String, Equatable {
    case snail, butterfly, bee, hedgehog
}

/// What a map node asks the child to do, and at which range.
enum MapActivity: Hashable {
    case build(LearningLevel)
    case pair(LearningLevel)
    case split(LearningLevel)
    case barBuild(maximum: Int)
    case barSplit(maximum: Int)
    /// Version 9: base-ten blocks (show, read or take away) at a place-value level.
    case placeValue(PlaceValueTask, PlaceValueLevel)
    /// Version 10: the equation balance in one of its three scaffold phases.
    case balance(BalancePhase)

    /// Child-facing name, also spoken when the node is named.
    var title: String {
        switch self {
        case .build(let level): return "Bygg tallet til \(level.maximum)"
        case .pair(let level): return "Finn tallvennen til \(level.maximum)"
        case .split(let level): return "Del opp til \(level.maximum)"
        case .barBuild(let maximum): return "Bygg med stolper til \(maximum)"
        case .barSplit(let maximum): return "Del stolpen til \(maximum)"
        case .placeValue(let task, let level): return "\(task.title) \(level.title)"
        case .balance(let phase): return "Likevekt \(phase.title)"
        }
    }

    /// The largest total the node ever shows.
    var maximum: Int {
        switch self {
        case .build(let level), .pair(let level), .split(let level): return level.maximum
        case .barBuild(let maximum), .barSplit(let maximum): return maximum
        case .placeValue(_, let level): return level.maximum
        case .balance(let phase): return BalanceRules.maximumAmount(for: phase)
        }
    }
}

/// One numbered stop on the map. Identifiers are stable storage keys: never rename one.
struct MapNode: Identifiable, Hashable {
    let id: String
    /// 1-based position across the whole map; shown on the node.
    let number: Int
    let activity: MapActivity
    /// Puzzles to solve before the node is complete.
    let taskCount: Int
}

/// A group of nodes hosted by one guide.
struct Island: Identifiable {
    let id: String
    let number: Int
    let title: String
    let guide: MapGuide
    let nodes: [MapNode]
}

/// The whole journey. Nodes unlock in order across islands; the first node is always open.
struct IslandMap {
    let islands: [Island]

    var nodes: [MapNode] { islands.flatMap(\.nodes) }

    func node(withID id: String) -> MapNode? {
        nodes.first { $0.id == id }
    }

    /// The node the child must complete before `node`, or nil for the first node.
    func predecessor(of node: MapNode) -> MapNode? {
        let all = nodes
        guard let index = all.firstIndex(of: node), index > 0 else { return nil }
        return all[index - 1]
    }

    func island(containing node: MapNode) -> Island? {
        islands.first { $0.nodes.contains(node) }
    }

    /// The map: bars first (with one bar node to 20 on the second island), then the three
    /// number games at 20, 40 and 100 (version 8), then place value (version 9) and the
    /// equation balance (version 10).
    static let standard: IslandMap = {
        var number = 0
        func node(_ id: String, _ activity: MapActivity) -> MapNode {
            number += 1
            return MapNode(id: id, number: number, activity: activity, taskCount: ChallengeRules.defaultTaskCount)
        }
        return IslandMap(islands: [
            Island(id: "bars", number: 1, title: "Stolpeøya", guide: .snail, nodes: [
                node("bars-build-5", .barBuild(maximum: 5)),
                node("bars-split-6", .barSplit(maximum: 6)),
                node("bars-build-10", .barBuild(maximum: 10)),
                node("bars-split-10", .barSplit(maximum: 10)),
            ]),
            Island(id: "twenty", number: 2, title: "Tjueøya", guide: .butterfly, nodes: [
                node("build-20", .build(.practice)),
                node("pair-20", .pair(.practice)),
                node("split-20", .split(.practice)),
                node("bars-build-20", .barBuild(maximum: 20)),
            ]),
            Island(id: "forty", number: 3, title: "Førtiøya", guide: .bee, nodes: [
                node("build-40", .build(.advanced)),
                node("pair-40", .pair(.advanced)),
                node("split-40", .split(.advanced)),
            ]),
            Island(id: "hundred", number: 4, title: "Hundreøya", guide: .hedgehog, nodes: [
                node("build-100", .build(.hundred)),
                node("pair-100", .pair(.hundred)),
                node("split-100", .split(.hundred)),
            ]),
            // Version 9: place value with base-ten blocks, its own level set (PlaceValueLevel).
            Island(id: "thousand", number: 5, title: "Tusenøya", guide: .hedgehog, nodes: [
                node("place-show-19", .placeValue(.show, .teens)),
                node("place-show-99", .placeValue(.show, .tens)),
                node("place-read-99", .placeValue(.read, .tens)),
                node("place-away-99", .placeValue(.takeAway, .tens)),
                node("place-show-999", .placeValue(.show, .hundreds)),
                node("place-read-9999", .placeValue(.read, .thousands)),
            ]),
            // Version 10: the equation balance, three scaffold phases.
            Island(id: "balance", number: 6, title: "Likevektsøya", guide: .butterfly, nodes: [
                node("balance-pictures", .balance(.pictorial)),
                node("balance-hybrid", .balance(.hybrid)),
                node("balance-symbols", .balance(.symbolic)),
            ]),
        ])
    }()
}

/// Stars and unlocks, persisted as one string under `StorageKey.islandStars`:
/// `nodeID=stars` pairs separated by commas, sorted by node identifier. Unknown or damaged
/// entries are dropped, stars are clamped to 0…3, and a node is unlocked when it is the first
/// node or its predecessor has at least one star, so no second key is needed for unlocks.
struct MapProgress: Equatable {
    private(set) var stars: [String: Int]

    init(serialized: String = "") {
        var parsed: [String: Int] = [:]
        for entry in serialized.split(separator: ",") {
            let pair = entry.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard pair.count == 2, !pair[0].isEmpty, let value = Int(pair[1]), value > 0 else { continue }
            parsed[pair[0]] = min(value, ChallengeRules.maximumStars)
        }
        stars = parsed
    }

    /// Stable text form for `@AppStorage`.
    var serialized: String {
        stars.filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
    }

    func stars(for node: MapNode) -> Int {
        stars[node.id] ?? 0
    }

    func isCompleted(_ node: MapNode) -> Bool {
        stars(for: node) > 0
    }

    func isUnlocked(_ node: MapNode, in map: IslandMap) -> Bool {
        guard let previous = map.predecessor(of: node) else { return true }
        return isCompleted(previous)
    }

    /// The first unlocked node that is not complete yet, or nil when everything is done.
    func nextNode(in map: IslandMap) -> MapNode? {
        map.nodes.first { isUnlocked($0, in: map) && !isCompleted($0) }
    }

    /// Keeps the best result. Returns true when the stored stars for the node went up.
    @discardableResult
    mutating func record(stars newStars: Int, for node: MapNode) -> Bool {
        let clamped = min(max(newStars, 0), ChallengeRules.maximumStars)
        guard clamped > stars(for: node) else { return false }
        stars[node.id] = clamped
        return true
    }

    func totalStars(in map: IslandMap) -> Int {
        map.nodes.reduce(0) { $0 + stars(for: $1) }
    }

    static func maximumStars(in map: IslandMap) -> Int {
        map.nodes.count * ChallengeRules.maximumStars
    }
}

/// How a finished node is rated. Completion always earns at least one star; mistakes (a wrong
/// answer or a refused piece) cost stars gently, and hints are free.
enum ChallengeRules {
    static let defaultTaskCount = 4
    static let maximumStars = 3

    static func stars(mistakes: Int) -> Int {
        switch mistakes {
        case ..<2: return 3
        case ..<4: return 2
        default: return 1
        }
    }
}

// MARK: - Plassverdi (place value)

/// The four places the block tray offers, from units to thousands. The raw value is the
/// power of ten, so `value` is 1, 10, 100 or 1000.
enum PlaceValueUnit: Int, CaseIterable, Comparable, Hashable {
    case ones = 0
    case tens = 1
    case hundreds = 2
    case thousands = 3

    static func < (lhs: PlaceValueUnit, rhs: PlaceValueUnit) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var value: Int {
        switch self {
        case .ones: return 1
        case .tens: return 10
        case .hundreds: return 100
        case .thousands: return 1000
        }
    }

    /// Plural name as the child hears it: "enere", "tiere", "hundrere", "tusenere".
    var title: String {
        switch self {
        case .ones: return "enere"
        case .tens: return "tiere"
        case .hundreds: return "hundrere"
        case .thousands: return "tusenere"
        }
    }

    var singular: String {
        switch self {
        case .ones: return "ener"
        case .tens: return "tier"
        case .hundreds: return "hundrer"
        case .thousands: return "tusener"
        }
    }

    /// The next place up, or nil above thousands.
    var next: PlaceValueUnit? {
        PlaceValueUnit(rawValue: rawValue + 1)
    }

    /// The next place down, or nil below ones.
    var previous: PlaceValueUnit? {
        PlaceValueUnit(rawValue: rawValue - 1)
    }

    /// Ten of a place make one of the next.
    static let regroupCount = 10
}

/// Blocks on the workspace, counted per place. The number shown is the weighted sum; a place
/// may hold ten or more blocks until `regroup` carries them up.
struct PlaceValueBlocks: Equatable {
    private var counts: [Int]

    init(ones: Int = 0, tens: Int = 0, hundreds: Int = 0, thousands: Int = 0) {
        counts = [max(0, ones), max(0, tens), max(0, hundreds), max(0, thousands)]
    }

    /// The canonical blocks of a number: every place below ten (4 tens and 7 ones for 47).
    init(number: Int) {
        let clamped = max(0, number)
        self.init(
            ones: clamped % 10,
            tens: (clamped / 10) % 10,
            hundreds: (clamped / 100) % 10,
            thousands: clamped / 1000
        )
    }

    subscript(unit: PlaceValueUnit) -> Int {
        get { counts[unit.rawValue] }
        set { counts[unit.rawValue] = max(0, newValue) }
    }

    var number: Int {
        PlaceValueUnit.allCases.reduce(0) { $0 + self[$1] * $1.value }
    }

    var totalBlocks: Int {
        counts.reduce(0, +)
    }

    var isEmpty: Bool {
        totalBlocks == 0
    }

    /// True when every place holds fewer than ten blocks.
    var isCanonical: Bool {
        counts.allSatisfy { $0 < PlaceValueUnit.regroupCount }
    }

    /// Carries ten blocks of a place into one of the next, from ones upward, as often as needed.
    /// Thousands are never regrouped. Returns how many carries happened per place
    /// (`[.ones: 1]` means ten ones became one ten).
    @discardableResult
    mutating func regroup() -> [PlaceValueUnit: Int] {
        var carries: [PlaceValueUnit: Int] = [:]
        for unit in PlaceValueUnit.allCases {
            guard let next = unit.next else { continue }
            let carry = self[unit] / PlaceValueUnit.regroupCount
            guard carry > 0 else { continue }
            self[unit] -= carry * PlaceValueUnit.regroupCount
            self[next] += carry
            carries[unit] = carry
        }
        return carries
    }

    /// Breaks one block of `unit` into ten of the place below (borrowing). False when the
    /// place is empty or there is no lower place.
    @discardableResult
    mutating func borrow(from unit: PlaceValueUnit) -> Bool {
        guard let lower = unit.previous, self[unit] > 0 else { return false }
        self[unit] -= 1
        self[lower] += PlaceValueUnit.regroupCount
        return true
    }
}

/// The level set of the place-value island, separate from `LearningLevel`: which numbers
/// appear and which places the tray offers.
enum PlaceValueLevel: Int, CaseIterable, Hashable {
    case teens = 1
    case tens = 2
    case hundreds = 3
    case thousands = 4

    var range: ClosedRange<Int> {
        switch self {
        case .teens: return 11...19
        case .tens: return 20...99
        case .hundreds: return 100...999
        case .thousands: return 1000...9999
        }
    }

    /// The places a child can use at this level, lowest first.
    var units: [PlaceValueUnit] {
        switch self {
        case .teens, .tens: return [.ones, .tens]
        case .hundreds: return [.ones, .tens, .hundreds]
        case .thousands: return [.ones, .tens, .hundreds, .thousands]
        }
    }

    /// The largest number of this level, for titles.
    var maximum: Int { range.upperBound }

    /// Child-facing range, for node titles: "til 19", "til 99", "til 999", "til 9999".
    var title: String { "til \(maximum)" }
}

/// What a place-value node asks for.
enum PlaceValueTask: Hashable {
    /// Build the target with blocks from the tray; ten of a place regroup by themselves.
    case show
    /// Read the blocks and pick the number among four choices.
    case read
    /// Start with blocks for a number, take some units away, breaking a ten when the ones run out.
    case takeAway

    var title: String {
        switch self {
        case .show: return "Vis tallet"
        case .read: return "Les tallet"
        case .takeAway: return "Ta bort og veksle"
        }
    }
}

enum PlaceValueRules {
    /// Most blocks a `show` task ever needs (the digit sum), so the longest task stays short.
    static let maximumDigitSum = 12

    static func digitSum(_ number: Int) -> Int {
        var remaining = max(0, number)
        var sum = 0
        while remaining > 0 {
            sum += remaining % 10
            remaining /= 10
        }
        return sum
    }

    /// Four distinct choices for a `read` task, all inside the level: the number itself and
    /// distractors that each differ in one place, the highest places first, so the biggest
    /// blocks have to be counted too (from hundreds upward the choices differ by a hundred and,
    /// with thousands, by a thousand), then the digit-swapped twin and nearby numbers.
    static func readChoices<G: RandomNumberGenerator>(for number: Int, level: PlaceValueLevel, using generator: inout G) -> [Int] {
        var options = [number]
        func offer(_ candidate: Int) {
            if level.range.contains(candidate), !options.contains(candidate), options.count < 4 {
                options.append(candidate)
            }
        }
        /// One place up or down, the direction chosen at random, the other direction as a
        /// fallback at the edge of the range.
        func offerStep(_ step: Int) {
            let up = Bool.random(using: &generator)
            offer(number + (up ? step : -step))
            offer(number + (up ? -step : step))
        }
        let tens = (number / 10) % 10
        let ones = number % 10
        switch level {
        case .thousands:
            offerStep(1000)
            offerStep(100)
            offerStep(10)
        case .hundreds:
            offerStep(100)
            offerStep(10)
            offer(number - tens * 10 - ones + ones * 10 + tens)
        case .teens, .tens:
            offer(number - tens * 10 - ones + ones * 10 + tens)
            offerStep(10)
        }
        offer(number + 10)
        offer(number - 10)
        offer(number + 1)
        offer(number - 1)
        offer(number + 100)
        offer(number - 100)
        var guardCount = 0
        while options.count < 4, guardCount < 1_000 {
            offer(Int.random(in: level.range, using: &generator))
            guardCount += 1
        }
        return options.shuffled(using: &generator)
    }
}

/// One place-value task.
struct PlaceValuePuzzle {
    let task: PlaceValueTask
    let level: PlaceValueLevel
    /// Show: the number to build. Read: the number the blocks show. Take away: the start number.
    let target: Int
    /// Take away only: how many units to remove (always more than the ones digit, so one ten
    /// must be broken). Zero otherwise.
    let amount: Int
    /// Read only: four distinct choices including `target`. Empty otherwise.
    let choices: [Int]

    /// What the workspace must show when the task is solved.
    var answer: Int {
        task == .takeAway ? target - amount : target
    }

    /// Take-away starts: at least 11, a ones digit below 9 and a tens digit of at least 1, so
    /// one ten (never a hundred) is broken.
    static func isTakeAwayTarget(_ number: Int) -> Bool {
        number >= 11 && number % 10 < 9 && (number / 10) % 10 >= 1
    }

    static func make(task: PlaceValueTask, level: PlaceValueLevel, target requestedTarget: Int? = nil) -> PlaceValuePuzzle {
        var generator = SystemRandomNumberGenerator()
        return make(task: task, level: level, target: requestedTarget, using: &generator)
    }

    static func make<G: RandomNumberGenerator>(
        task: PlaceValueTask,
        level: PlaceValueLevel,
        target requestedTarget: Int? = nil,
        using generator: inout G
    ) -> PlaceValuePuzzle {
        let range = level.range
        var target = requestedTarget ?? Int.random(in: range, using: &generator)
        precondition(range.contains(target), "Place-value target outside the level")
        switch task {
        case .show:
            // Keep the digit sum small so the longest task stays a handful of drags.
            var guardCount = 0
            while requestedTarget == nil, PlaceValueRules.digitSum(target) > PlaceValueRules.maximumDigitSum, guardCount < 1_000 {
                target = Int.random(in: range, using: &generator)
                guardCount += 1
            }
            return PlaceValuePuzzle(task: .show, level: level, target: target, amount: 0, choices: [])
        case .read:
            return PlaceValuePuzzle(
                task: .read,
                level: level,
                target: target,
                amount: 0,
                choices: PlaceValueRules.readChoices(for: target, level: level, using: &generator)
            )
        case .takeAway:
            // Exactly one ten must be broken: the amount exceeds the ones digit (so the digit is
            // below 9), a ten is there to break (tens digit at least 1), and the result stays positive.
            var guardCount = 0
            while requestedTarget == nil, !isTakeAwayTarget(target), guardCount < 1_000 {
                target = Int.random(in: range, using: &generator)
                guardCount += 1
            }
            precondition(isTakeAwayTarget(target), "Take-away targets need one ten to break and room for the amount")
            let ones = target % 10
            let amount = Int.random(in: (ones + 1)...9, using: &generator)
            return PlaceValuePuzzle(task: .takeAway, level: level, target: target, amount: amount, choices: [])
        }
    }
}

// MARK: - Likevekt (equation balance)

/// The three scaffold phases: pictures only, pictures with numerals and signs, then symbols.
enum BalancePhase: Int, CaseIterable, Hashable {
    case pictorial = 1
    case hybrid = 2
    case symbolic = 3

    var title: String {
        switch self {
        case .pictorial: return "med bilder"
        case .hybrid: return "med bilder og tall"
        case .symbolic: return "med tall og tegn"
        }
    }
}

/// One card on a side of the board or in the hand: a positive amount, or its opposite (an
/// inverse card). A card keeps its identity for as long as it lies on the board, so the view
/// can mirror it, fade it in and let it vanish.
struct BalanceCard: Identifiable, Equatable {
    let id: UUID
    let value: Int
    let isInverse: Bool

    init(value: Int, isInverse: Bool, id: UUID = UUID()) {
        self.id = id
        self.value = value
        self.isInverse = isInverse
    }

    var signedValue: Int { isInverse ? -value : value }
}

/// A move on the board: the same card on both sides, or both sides split into equal parts.
enum BalanceMove: Hashable {
    case add(value: Int, inverse: Bool)
    case divide(by: Int)
}

enum BalanceRules {
    /// The card amounts a child can add, in either polarity.
    static let cardValues = [1, 2, 5, 10]

    /// The most either side may hold. The boards never need more, every card stays on screen,
    /// and no amount on the board is ever negative: an inverse card only takes away what the
    /// left side holds (the right side always holds at least as much).
    static func maximumAmount(for phase: BalancePhase) -> Int {
        switch phase {
        case .pictorial: return 15
        case .hybrid: return 25
        case .symbolic: return 30
        }
    }

    /// New cards that show an amount, biggest first (7 → 5 and 2); zero gives none. Used when a
    /// board starts, after a division and for the change when part of a card is taken away.
    static func cards(for amount: Int) -> [BalanceCard] {
        var remaining = max(0, amount)
        var result: [BalanceCard] = []
        for value in cardValues.sorted(by: >) {
            while remaining >= value {
                result.append(BalanceCard(value: value, isInverse: false))
                remaining -= value
            }
        }
        return result
    }

    /// Both sides equal: coefficient × unknown plus the left amount against the right amount.
    static func isBalanced(unknown: Int, coefficient: Int, left: Int, right: Int) -> Bool {
        coefficient * unknown + left == right
    }

    /// The board after `move`, or nil when the move is not allowed: a card must keep the left
    /// side at zero or more and both sides at most `maximum`; a division needs the divisor to
    /// divide the number of hidden numbers and both amounts.
    static func apply(_ move: BalanceMove, coefficient: Int, left: Int, right: Int, maximum: Int) -> (coefficient: Int, left: Int, right: Int)? {
        switch move {
        case .add(let value, let inverse):
            guard cardValues.contains(value) else { return nil }
            let signed = inverse ? -value : value
            let newLeft = left + signed
            let newRight = right + signed
            guard newLeft >= 0, newRight >= 0, newLeft <= maximum, newRight <= maximum else { return nil }
            return (coefficient, newLeft, newRight)
        case .divide(let divisor):
            guard divisor >= 2, coefficient % divisor == 0, left % divisor == 0, right % divisor == 0 else { return nil }
            return (coefficient / divisor, left / divisor, right / divisor)
        }
    }

    /// Every move in the order the search tries them: a division first, then inverse cards from
    /// the biggest, then positive cards from the smallest. Among shortest solutions the search
    /// therefore prefers dividing and the biggest inverse card.
    static func candidateMoves(coefficient: Int) -> [BalanceMove] {
        [2, 3].filter { coefficient > 1 && coefficient % $0 == 0 }.map { BalanceMove.divide(by: $0) }
            + cardValues.sorted(by: >).map { BalanceMove.add(value: $0, inverse: true) }
            + cardValues.map { BalanceMove.add(value: $0, inverse: false) }
    }

    /// A shortest solution from this board (breadth-first over the boards the allowed moves
    /// reach; the goal is one hidden number alone on the left). Empty when the board is solved,
    /// nil when it cannot be solved (never for a generated board).
    static func shortestSolution(coefficient: Int, left: Int, right: Int, maximum: Int) -> [BalanceMove]? {
        struct Board: Hashable { let coefficient: Int, left: Int, right: Int }
        let start = Board(coefficient: coefficient, left: left, right: right)
        if coefficient == 1, left == 0 { return [] }
        var cameFrom: [Board: (Board, BalanceMove)] = [:]
        var seen: Set<Board> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let board = queue[head]
            head += 1
            for move in candidateMoves(coefficient: board.coefficient) {
                guard let next = apply(move, coefficient: board.coefficient, left: board.left, right: board.right, maximum: maximum) else { continue }
                let reached = Board(coefficient: next.coefficient, left: next.left, right: next.right)
                guard seen.insert(reached).inserted else { continue }
                cameFrom[reached] = (board, move)
                if reached.coefficient == 1, reached.left == 0 {
                    var path: [BalanceMove] = []
                    var current = reached
                    while let entry = cameFrom[current] {
                        path.append(entry.1)
                        current = entry.0
                    }
                    return path.reversed()
                }
                queue.append(reached)
            }
        }
        return nil
    }

    /// Stars for a solved board: three within the shortest solution, two within two extra
    /// moves, one otherwise.
    static func stars(moves: Int, optimal: Int) -> Int {
        switch moves - optimal {
        case ...0: return 3
        case ...2: return 2
        default: return 1
        }
    }
}

/// `coefficient` hidden numbers plus `leftConstant` on the left balance `rightConstant`.
struct BalancePuzzle {
    let phase: BalancePhase
    let unknown: Int
    let coefficient: Int
    let leftConstant: Int

    var rightConstant: Int { coefficient * unknown + leftConstant }
    var maximum: Int { BalanceRules.maximumAmount(for: phase) }

    /// The number of moves of a shortest solution; the board's stars compare with it.
    var optimalMoves: Int {
        BalanceRules.shortestSolution(coefficient: coefficient, left: leftConstant, right: rightConstant, maximum: maximum)?.count ?? 0
    }

    static func make(phase: BalancePhase) -> BalancePuzzle {
        var generator = SystemRandomNumberGenerator()
        return make(phase: phase, using: &generator)
    }

    /// Pictures: one hidden number and a left amount of 1…5, right side at most 10. Hybrid:
    /// amounts to 9, right side at most 18. Symbols: one to three hidden numbers, left amount
    /// 0…6 (never 0 with a single hidden number), right side at most 24.
    static func make<G: RandomNumberGenerator>(phase: BalancePhase, using generator: inout G) -> BalancePuzzle {
        switch phase {
        case .pictorial:
            return BalancePuzzle(
                phase: phase,
                unknown: Int.random(in: 1...5, using: &generator),
                coefficient: 1,
                leftConstant: Int.random(in: 1...5, using: &generator)
            )
        case .hybrid:
            return BalancePuzzle(
                phase: phase,
                unknown: Int.random(in: 1...9, using: &generator),
                coefficient: 1,
                leftConstant: Int.random(in: 1...9, using: &generator)
            )
        case .symbolic:
            let coefficient = Int.random(in: 1...3, using: &generator)
            let leftConstant = Int.random(in: (coefficient == 1 ? 1 : 0)...6, using: &generator)
            return BalancePuzzle(
                phase: phase,
                unknown: Int.random(in: 1...6, using: &generator),
                coefficient: coefficient,
                leftConstant: leftConstant
            )
        }
    }
}
