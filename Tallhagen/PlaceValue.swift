import SwiftUI

// Plassverdi: base-ten blocks for 11–9999. Ones are small squares, tens are the brown rods of
// the number bars, hundreds are 10 x 10 tiles and thousands are cubes drawn with a top and a
// side face, all at one scale (`PlaceBlockStyle.unit`). The workspace has one column per
// place; ten blocks of a place regroup into one of the next with a short carrying animation,
// and tapping a rod in a take-away task breaks it into ten units (borrowing). Tapping a tray
// bin is the first-class alternative to dragging a block from it. Rules live in
// MathLogic.swift (`PlaceValueBlocks`, `PlaceValuePuzzle`), state in GameSessions.swift
// (`PlaceValueSession`). Original drawings: plain blocks, no faces, no third-party likeness.

enum PlaceBlockStyle {
    /// Side of one unit block, and the thickness of a rod.
    static let unit: CGFloat = 11
    static let rodLength: CGFloat = unit * 10
    static let tileSide: CGFloat = unit * 10
    /// Depth of the cube's top and side faces.
    static let cubeDepth: CGFloat = 26
    /// Gap between blocks in a stack, and the offset between fanned tiles and cubes.
    static let gap: CGFloat = 3
    /// Fanned tiles and cubes step 12 pt, so every edge can be counted in a reading task.
    static let fan: CGFloat = 12
    /// A ten-frame of loose ones: two columns of five unit squares.
    static let frameWidth: CGFloat = unit * 2 + gap
    static let frameHeight: CGFloat = unit * 5 + gap * 4

    /// Width a place's blocks can ever need, so a column never changes width during a task and
    /// the layout never switches under the child's finger: nine blocks, or two ten-frames of
    /// ones when a take-away task has broken a ten.
    static func columnWidth(for unit: PlaceValueUnit, task: PlaceValueTask) -> CGFloat {
        switch unit {
        case .ones: return task == .takeAway ? frameWidth * 2 + 8 : frameWidth
        case .tens: return Self.unit * 9 + 5 * 8
        case .hundreds, .thousands: return size(of: unit).width + fan * 8
        }
    }

    static func colour(for unit: PlaceValueUnit) -> Color {
        switch unit {
        case .ones: return BarPalette.colour(for: 1)
        case .tens: return BarPalette.colour(for: 10)
        case .hundreds: return GardenStyle.teal
        case .thousands: return BarPalette.colour(for: 7)
        }
    }

    /// Size of one block's drawing.
    static func size(of unit: PlaceValueUnit) -> CGSize {
        switch unit {
        case .ones: return CGSize(width: Self.unit, height: Self.unit)
        case .tens: return CGSize(width: Self.unit, height: rodLength)
        case .hundreds: return CGSize(width: tileSide, height: tileSide)
        case .thousands: return CGSize(width: tileSide + cubeDepth, height: tileSide + cubeDepth)
        }
    }
}

/// One base-ten block.
struct PlaceBlockView: View {
    let unit: PlaceValueUnit

    private var colour: Color { PlaceBlockStyle.colour(for: unit) }
    private var line: Color { Color.white.opacity(unit == .tens ? 0.75 : 0.45) }

    var body: some View {
        let size = PlaceBlockStyle.size(of: unit)
        Group {
            switch unit {
            case .ones:
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(colour)
                    .overlay { RoundedRectangle(cornerRadius: 2.5).strokeBorder(Color.white.opacity(0.6), lineWidth: 1) }
            case .tens:
                RoundedRectangle(cornerRadius: 3)
                    .fill(colour)
                    .overlay { gridLines(columns: 1, rows: 10, size: size) }
                    .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(GardenStyle.ink.opacity(0.3), lineWidth: 1) }
            case .hundreds:
                RoundedRectangle(cornerRadius: 4)
                    .fill(colour)
                    .overlay { gridLines(columns: 10, rows: 10, size: size) }
                    .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(GardenStyle.ink.opacity(0.6), lineWidth: 1.5) }
            case .thousands:
                CubeDrawing(colour: colour)
            }
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    private func gridLines(columns: Int, rows: Int, size: CGSize) -> some View {
        Path { path in
            for column in 1..<columns {
                let x = size.width * CGFloat(column) / CGFloat(columns)
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for row in 1..<rows {
                let y = size.height * CGFloat(row) / CGFloat(rows)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(line, lineWidth: 1)
    }
}

/// A thousand: a front face with a 10 x 10 grid, a lighter top face and a darker side face.
private struct CubeDrawing: View {
    let colour: Color

    var body: some View {
        let side = PlaceBlockStyle.tileSide
        let depth = PlaceBlockStyle.cubeDepth
        ZStack(alignment: .bottomLeading) {
            // Top face.
            Path { path in
                path.move(to: CGPoint(x: 0, y: depth))
                path.addLine(to: CGPoint(x: depth, y: 0))
                path.addLine(to: CGPoint(x: side + depth, y: 0))
                path.addLine(to: CGPoint(x: side, y: depth))
                path.closeSubpath()
            }
            .fill(colour.opacity(0.65))
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: depth))
                    path.addLine(to: CGPoint(x: depth, y: 0))
                    path.addLine(to: CGPoint(x: side + depth, y: 0))
                    path.addLine(to: CGPoint(x: side, y: depth))
                    path.closeSubpath()
                }
                .stroke(GardenStyle.ink.opacity(0.3), lineWidth: 1)
            }
            // Side face.
            Path { path in
                path.move(to: CGPoint(x: side, y: depth))
                path.addLine(to: CGPoint(x: side + depth, y: 0))
                path.addLine(to: CGPoint(x: side + depth, y: side))
                path.addLine(to: CGPoint(x: side, y: side + depth))
                path.closeSubpath()
            }
            .fill(colour)
            .overlay {
                // Darker side face (no iOS 18 colour mixing needed).
                Path { path in
                    path.move(to: CGPoint(x: side, y: depth))
                    path.addLine(to: CGPoint(x: side + depth, y: 0))
                    path.addLine(to: CGPoint(x: side + depth, y: side))
                    path.addLine(to: CGPoint(x: side, y: side + depth))
                    path.closeSubpath()
                }
                .fill(Color.black.opacity(0.28))
            }
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: side, y: depth))
                    path.addLine(to: CGPoint(x: side + depth, y: 0))
                    path.addLine(to: CGPoint(x: side + depth, y: side))
                    path.addLine(to: CGPoint(x: side, y: side + depth))
                    path.closeSubpath()
                }
                .stroke(GardenStyle.ink.opacity(0.3), lineWidth: 1)
            }
            // Front face with the grid.
            RoundedRectangle(cornerRadius: 3)
                .fill(colour)
                .overlay {
                    Path { path in
                        for index in 1..<10 {
                            let offset = side * CGFloat(index) / 10
                            path.move(to: CGPoint(x: offset, y: 0))
                            path.addLine(to: CGPoint(x: offset, y: side))
                            path.move(to: CGPoint(x: 0, y: offset))
                            path.addLine(to: CGPoint(x: side, y: offset))
                        }
                    }
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                }
                .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(GardenStyle.ink.opacity(0.6), lineWidth: 1.5) }
                .frame(width: side, height: side)
                .offset(y: 0)
        }
        .frame(width: side + depth, height: side + depth, alignment: .bottomLeading)
    }
}

/// A tray bin: tap to add one block of its place, or drag a block out of it.
private struct TrayBin: View {
    let unit: PlaceValueUnit
    let tint: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                PlaceBlockView(unit: unit)
                    .scaleEffect(unit == .ones ? 2 : (unit == .tens ? 0.8 : 0.55))
                    .frame(width: 80, height: 90)
                Text(unit.singular)
                    .font(.garden(.subheadline, weight: .bold))
                    .foregroundStyle(GardenStyle.ink)
            }
            .frame(minWidth: 96, minHeight: 136)
            .padding(8)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
            }
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel("Brikke: \(unit.singular)")
        .accessibilityHint("Trykk for å legge én \(unit.singular) på arbeidsplassen, eller dra den dit")
        .accessibilityIdentifier("place.tray.\(unit.rawValue)")
    }
}

/// A number to pick in a reading task.
private struct NumeralChoiceCard: View {
    let number: Int
    let tint: Color
    let isTried: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(verbatim: String(number))
                .font(.display(40))
                .monospacedDigit()
                .foregroundStyle(GardenStyle.ink)
                .opacity(isTried ? 0.65 : 1)
            if isTried {
                Label("Prøvd", systemImage: "xmark.circle")
                    .font(.garden(.footnote, weight: .bold))
                    .foregroundStyle(GardenStyle.ink)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tallet \(number)")
    }
}

/// The place-value activity of a map node.
struct PlaceValueView: View {
    let task: PlaceValueTask
    let level: PlaceValueLevel

    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.challengeHost) private var challenge
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var session: PlaceValueSession
    /// The blocks before the last carry, shown for a moment so the ten blocks are seen before
    /// they become one; nil otherwise.
    @State private var beforeCarry: PlaceValueBlocks?
    @State private var isDropTargeted = false

    init(task: PlaceValueTask, level: PlaceValueLevel) {
        self.task = task
        self.level = level
        _session = State(initialValue: PlaceValueSession(task: task, level: level))
    }

    private var tint: Color { GardenStyle.soil }
    private var shownBlocks: PlaceValueBlocks { beforeCarry ?? session.blocks }

    /// Columns on the workspace: the level's places, highest first.
    private var columns: [PlaceValueUnit] {
        level.units.reversed()
    }

    var body: some View {
        GameScaffold(
            title: "Plassverdi",
            subtitle: subtitle,
            tint: tint,
            creature: .hedgehog,
            mood: session.isSolved ? .happy : (session.hasStarted ? .thinking : .idle),
            progress: session.task == .show ? Double(session.number) / Double(max(session.target, 1)) : (session.isSolved ? 1 : 0)
        ) {
            taskPanel

            if session.task == .show {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 20) {
                        tray
                        workspace
                    }
                    VStack(spacing: 18) {
                        tray
                        workspace
                    }
                }
            } else {
                workspace
            }

            if session.task == .read {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 14)], spacing: 14) {
                    ForEach(session.choices, id: \.self) { choice in
                        let tried = session.triedChoices.contains(choice)
                        Button {
                            answer(choice)
                        } label: {
                            NumeralChoiceCard(number: choice, tint: tint, isTried: tried)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .disabled(session.isSolved)
                        .accessibilityHint(tried ? "Du har prøvd dette tallet" : "Trykk for å svare \(choice)")
                        .accessibilityIdentifier("place.choice.\(choice)")
                    }
                }
            }

            if let feedback = session.feedback {
                StatusMessage(text: feedback, isSuccess: session.isSolved)
            }

            if session.isSolved {
                BigActionButton(
                    label: "Neste oppgave",
                    symbol: "arrow.right.circle.fill",
                    tint: tint,
                    identifier: "game.next",
                    hint: "Lager en ny oppgave",
                    action: startNewPuzzle
                )
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        readPromptButton
                        hintButton
                        Spacer(minLength: 0)
                        if session.task == .takeAway { restoreButton }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        readPromptButton
                        hintButton
                        if session.task == .takeAway { restoreButton }
                    }
                }
            }
        }
        .onAppear(perform: speakPromptIfEnabled)
    }

    private var subtitle: String {
        switch session.task {
        case .show: return "Legg brikker på arbeidsplassen til tallet er bygget. Ti like brikker blir til én større."
        case .read: return "Tell brikkene og velg tallet de viser."
        case .takeAway: return "Trykk på enerne for å ta bort. Trykk på en tier for å veksle den i ti enere."
        }
    }

    // MARK: Task

    private var taskPanel: some View {
        WhitePanel {
            VStack(spacing: 10) {
                switch session.task {
                case .show:
                    Text("Vis tallet")
                        .font(.garden(.title3, weight: .semibold))
                        .foregroundStyle(GardenStyle.muted)
                    Text(verbatim: String(session.target))
                        .font(.display(64))
                        .monospacedDigit()
                        .foregroundStyle(GardenStyle.purple)
                        .accessibilityLabel(session.prompt)
                        .accessibilityIdentifier("place.target")
                case .read:
                    Text("Hvilket tall viser brikkene?")
                        .font(.garden(.title2, weight: .bold))
                        .foregroundStyle(GardenStyle.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityLabel(session.prompt)
                        .accessibilityIdentifier("place.target")
                case .takeAway:
                    Text("Ta bort")
                        .font(.garden(.title3, weight: .semibold))
                        .foregroundStyle(GardenStyle.muted)
                    HStack(spacing: 14) {
                        Text(verbatim: String(session.target))
                            .font(.display(56))
                            .monospacedDigit()
                            .foregroundStyle(GardenStyle.purple)
                        Text("−")
                            .font(.display(40))
                            .foregroundStyle(GardenStyle.ink)
                        Text(verbatim: String(session.target - session.answer))
                            .font(.display(56))
                            .monospacedDigit()
                            .foregroundStyle(GardenStyle.teal)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(session.prompt)
                    .accessibilityIdentifier("place.target")
                    Text(verbatim: "Tatt bort: \(session.target - session.number) av \(session.target - session.answer)")
                        .font(.garden(.subheadline, weight: .semibold))
                        .foregroundStyle(GardenStyle.muted)
                        .monospacedDigit()
                        .accessibilityIdentifier("place.removed")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Tray and workspace

    private var tray: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Brikker")
                .font(.garden(.subheadline, weight: .bold))
                .foregroundStyle(GardenStyle.muted)
                .accessibilityAddTraits(.isHeader)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) { bins }
                VStack(spacing: 10) { bins }
            }
        }
    }

    @ViewBuilder
    private var bins: some View {
        ForEach(columns, id: \.self) { unit in
            let bin = TrayBin(unit: unit, tint: tint, isEnabled: !session.isSolved) {
                add(unit)
            }
            if session.isSolved {
                bin
            } else {
                bin.draggable("place.\(unit.rawValue)")
            }
        }
    }

    private var columnsRow: some View {
        HStack(alignment: .bottom, spacing: 14) {
            ForEach(columns, id: \.self) { unit in
                column(unit)
            }
        }
        .padding(16)
    }

    private var workspace: some View {
        VStack(spacing: 10) {
            // The columns keep their widths for the whole task; only a window narrower than
            // nine cubes and their neighbours (Split View) makes the row scroll sideways.
            ViewThatFits(in: .horizontal) {
                columnsRow
                ScrollView(.horizontal) { columnsRow }
            }
            .frame(maxWidth: .infinity, minHeight: PlaceBlockStyle.rodLength + 90)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(isDropTargeted ? tint : GardenStyle.lightLine, style: StrokeStyle(lineWidth: isDropTargeted ? 3 : 1.2, dash: isDropTargeted ? [10, 6] : []))
            }
            .dropDestination(for: String.self) { items, _ in
                guard let item = items.first, item.hasPrefix("place."),
                      let raw = Int(item.dropFirst("place.".count)), let unit = PlaceValueUnit(rawValue: raw)
                else { return false }
                return add(unit) != .rejected
            } isTargeted: { targeted in
                isDropTargeted = targeted && session.task == .show && !session.isSolved
            }

            if session.task != .read {
                Text(verbatim: "Ditt tall: \(session.number)")
                    .font(.display(26))
                    .monospacedDigit()
                    .foregroundStyle(GardenStyle.ink)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("place.number")
            }
        }
    }

    /// One place on the workspace: its name and digit above the stacked blocks. In show and
    /// take-away tasks the whole column is a button: it takes one block away (ones, or any
    /// place while showing) or breaks a block into ten smaller ones (take away).
    private func column(_ unit: PlaceValueUnit) -> some View {
        let count = shownBlocks[unit]
        let content = VStack(spacing: 8) {
            // In a reading task the digits above the columns would spell the answer, so the
            // child counts the blocks; VoiceOver still hears the count in the column label.
            if session.task != .read {
                Text(verbatim: String(count))
                    .font(.display(28))
                    .monospacedDigit()
                    .foregroundStyle(count > 0 ? PlaceBlockStyle.colour(for: unit) : GardenStyle.muted)
                    .contentTransition(.numericText())
            }
            Text(unit.title)
                .font(.garden(.caption, weight: .bold))
                .foregroundStyle(GardenStyle.muted)
            blocks(unit, count: count)
                .frame(maxWidth: .infinity, minHeight: PlaceBlockStyle.rodLength + 10, alignment: .bottom)
        }
        .frame(minWidth: PlaceBlockStyle.columnWidth(for: unit, task: session.task) + 16, maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(PlaceBlockStyle.colour(for: unit).opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

        return Group {
            if session.task == .read {
                content
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(columnLabel(unit, count: count))
            } else {
                Button {
                    tapColumn(unit)
                } label: {
                    content
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(session.isSolved || count == 0)
                .accessibilityLabel(columnLabel(unit, count: count))
                .accessibilityHint(columnHint(unit))
            }
        }
        .accessibilityIdentifier("place.column.\(unit.rawValue)")
    }

    private func columnLabel(_ unit: PlaceValueUnit, count: Int) -> String {
        "\(unit.title): \(count)"
    }

    private func columnHint(_ unit: PlaceValueUnit) -> String {
        switch session.task {
        case .show: return "Trykk for å ta bort én \(unit.singular)"
        case .takeAway: return unit == .ones ? "Trykk for å ta bort én ener" : "Trykk for å veksle én \(unit.singular) i ti mindre brikker"
        case .read: return ""
        }
    }

    /// The blocks of one place, stacked so that even nine fit: rods side by side, loose ones in
    /// ten-frames (two columns of five, filled from the bottom, at the same size as a rod's unit
    /// cells, so ten ones are exactly as big as the rod they become), tiles and cubes fanned.
    @ViewBuilder
    private func blocks(_ unit: PlaceValueUnit, count: Int) -> some View {
        switch unit {
        case .ones:
            let frames = max(1, (count + 9) / 10)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<frames, id: \.self) { frame in
                    let inFrame = min(10, count - frame * 10)
                    HStack(alignment: .bottom, spacing: PlaceBlockStyle.gap) {
                        ForEach(0..<2, id: \.self) { half in
                            VStack(spacing: PlaceBlockStyle.gap) {
                                ForEach(0..<max(0, min(5, inFrame - half * 5)), id: \.self) { _ in
                                    PlaceBlockView(unit: .ones)
                                        .transition(blockTransition(unit))
                                }
                            }
                            .frame(width: PlaceBlockStyle.unit, height: PlaceBlockStyle.frameHeight, alignment: .bottom)
                        }
                    }
                }
            }
        case .tens:
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<count, id: \.self) { _ in
                    PlaceBlockView(unit: .tens)
                        .transition(blockTransition(unit))
                }
            }
        case .hundreds, .thousands:
            let fan = PlaceBlockStyle.fan
            ZStack(alignment: .bottomLeading) {
                ForEach(0..<count, id: \.self) { index in
                    PlaceBlockView(unit: unit)
                        .offset(x: CGFloat(index) * fan, y: -CGFloat(index) * fan)
                        .transition(blockTransition(unit))
                }
            }
            .frame(
                width: PlaceBlockStyle.size(of: unit).width + CGFloat(max(count - 1, 0)) * fan,
                height: PlaceBlockStyle.size(of: unit).height + CGFloat(max(count - 1, 0)) * fan,
                alignment: .bottomLeading
            )
        }
    }

    /// Blocks scale in where they arrive (from the tray, from a carry, from a broken block) and
    /// slide off towards the next place up when they leave (a carry, or a block taken away).
    /// Plain under Reduce Motion.
    private func blockTransition(_ unit: PlaceValueUnit) -> AnyTransition {
        if reduceMotion { return .identity }
        return .asymmetric(
            insertion: .scale(scale: 0.4, anchor: .bottom).combined(with: .opacity),
            removal: .offset(x: -36, y: -10).combined(with: .opacity)
        )
    }

    // MARK: Buttons

    private var readPromptButton: some View {
        SecondaryActionButton(label: "Les opp oppgaven", symbol: "speaker.wave.2.fill", tint: tint, identifier: "game.readPrompt", action: readPromptAloud)
    }

    private var hintButton: some View {
        SecondaryActionButton(label: "Få et hint", symbol: "lightbulb.fill", tint: tint, identifier: "place.hint", action: showHint)
    }

    private var restoreButton: some View {
        SecondaryActionButton(label: "Legg tilbake", symbol: "arrow.uturn.backward", tint: tint, identifier: "place.restore", action: restoreLast)
    }

    // MARK: Actions

    @discardableResult
    private func add(_ unit: PlaceValueUnit) -> AnswerOutcome {
        guard beforeCarry == nil else { return .ignored }
        let before = session.blocks
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.add(unit)
        }
        if outcome != .rejected, outcome != .ignored, !session.lastCarries.isEmpty, !reduceMotion {
            // Show the ten blocks for a moment, then let them become one.
            var preview = before
            preview[unit] += 1
            beforeCarry = preview
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    beforeCarry = nil
                }
            }
        }
        respond(to: outcome)
        return outcome
    }

    private func tapColumn(_ unit: PlaceValueUnit) {
        guard beforeCarry == nil else { return }
        let outcome: AnswerOutcome
        if session.task == .takeAway, unit != .ones {
            outcome = withAnimation(Motion.spring(reduceMotion)) { session.borrow(unit) }
        } else {
            outcome = withAnimation(Motion.spring(reduceMotion)) { session.removeOne(unit) }
        }
        respond(to: outcome)
    }

    private func restoreLast() {
        let outcome = withAnimation(Motion.spring(reduceMotion)) { session.restoreLast() }
        respond(to: outcome)
    }

    private func answer(_ choice: Int) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) { session.answer(choice) }
        respond(to: outcome)
    }

    private func showHint() {
        session.showHint()
        if let feedback = session.feedback {
            VoiceOverAnnouncer.announce(feedback)
            NorwegianVoice.shared.say(feedback, enabled: voice)
        }
    }

    private func readPromptAloud() {
        NorwegianVoice.shared.say(session.prompt, enabled: true, deferToVoiceOver: false)
    }

    private func speakPromptIfEnabled() {
        NorwegianVoice.shared.say(session.prompt, enabled: voice)
    }

    private func startNewPuzzle() {
        withAnimation(Motion.quick(reduceMotion)) {
            session = PlaceValueSession(task: task, level: level)
            beforeCarry = nil
        }
        speakPromptIfEnabled()
    }

    private func respond(to outcome: AnswerOutcome) {
        if outcome == .solved {
            solvedTotal += 1
        }
        challenge?.report(outcome)
        GameFeedback.react(to: outcome, feedback: session.feedback, voiceEnabled: voice)
    }
}
