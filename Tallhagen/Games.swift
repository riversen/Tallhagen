import SwiftUI

// The four activity screens. Mathematical rules live in MathLogic.swift and the state
// transitions in GameSessions.swift; these views add layout, animation, haptics and speech.

// MARK: - Bygg tallet

struct BuildGameView: View {
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.challengeHost) private var challenge

    @State private var session: BuildSession
    @State private var isDropTargeted = false
    /// A map node pins its range; free play follows the stored level.
    private let fixedLevel: LearningLevel?

    init(level: LearningLevel? = nil) {
        fixedLevel = level
        _session = State(initialValue: BuildSession(level: level ?? .stored()))
    }

    var body: some View {
        GameScaffold(
            title: "Bygg tallet",
            subtitle: "Velg brikker som til sammen blir måltallet.",
            tint: GardenStyle.teal,
            creature: .snail,
            // Attentive once the first piece is placed, happy while solved; a wrong piece
            // changes nothing.
            mood: session.isSolved ? .happy : (session.selected.isEmpty ? .idle : .thinking),
            progress: Double(session.currentTotal) / Double(max(session.target, 1))
        ) {
            targetPanel
            piecesSection

            if let feedback = session.feedback {
                StatusMessage(text: feedback, isSuccess: session.isSolved)
            }

            if session.isSolved {
                BigActionButton(
                    label: "Neste oppgave",
                    symbol: "arrow.right.circle.fill",
                    tint: GardenStyle.teal,
                    identifier: "game.next",
                    hint: "Lager et nytt måltall",
                    sound: .paper,
                    action: startNewPuzzle
                )
            } else {
                // One row where it fits (regular widths), stacked at compact widths or huge text.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        readPromptButton
                        hintButton
                        Spacer(minLength: 0)
                        restartButton
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        readPromptButton
                        hintButton
                        restartButton
                    }
                }
            }
        }
        .onAppear(perform: speakPromptIfEnabled)
    }

    private var readPromptButton: some View {
        SecondaryActionButton(
            label: "Les opp oppgaven",
            symbol: "speaker.wave.2.fill",
            tint: GardenStyle.teal,
            identifier: "game.readPrompt",
            action: readPromptAloud
        )
    }

    private var hintButton: some View {
        SecondaryActionButton(
            label: "Få et hint",
            symbol: "lightbulb.fill",
            tint: GardenStyle.teal,
            identifier: "build.hint",
            action: showHint
        )
    }

    private var restartButton: some View {
        SecondaryActionButton(
            label: "Start på nytt",
            symbol: "arrow.counterclockwise",
            tint: GardenStyle.teal,
            identifier: "build.restart",
            action: clearSelection
        )
    }

    private var targetPanel: some View {
        WhitePanel {
            VStack(spacing: 16) {
                Text("Kan du lage")
                    .font(.garden(.title3, weight: .semibold))
                    .foregroundStyle(GardenStyle.muted)

                Text("\(session.target)?")
                    .font(.display(72))
                    .foregroundStyle(GardenStyle.purple)
                    .accessibilityLabel("Måltallet er \(session.target)")
                    .accessibilityIdentifier("build.target")

                BeadGroup(count: session.target, tint: GardenStyle.purple, diameter: 17, maxColumns: session.level.dotColumns)

                Divider().padding(.vertical, 8)

                Text("Ditt tall: \(session.currentTotal)")
                    .font(.display(28))
                    .monospacedDigit()
                    .foregroundStyle(GardenStyle.ink)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("build.currentTotal")

                selectedArea
            }
            .frame(maxWidth: .infinity)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(isDropTargeted ? GardenStyle.teal : .clear, lineWidth: 5)
        }
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first else { return false }
            return drop(idString)
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted && !session.isSolved
        }
    }

    /// Tall enough for a chip holding the puzzle's largest piece, so the layout below the
    /// answer area stays put while pieces come and go.
    private var answerAreaHeight: CGFloat {
        let largest = session.puzzle.pieces.map(\.value).max() ?? 1
        return max(54, BeadGroup.height(forCount: largest, diameter: 7, maxColumns: session.level.dotColumns) + 31 + 4 + 12)
    }

    @ViewBuilder
    private var selectedArea: some View {
        if session.selected.isEmpty {
            Text("Dra brikker hit, eller trykk på dem nedenfor.")
                .font(.garden(.body))
                .foregroundStyle(GardenStyle.muted)
                .multilineTextAlignment(.center)
                .frame(minHeight: answerAreaHeight)
        } else {
            // Centred when the chips fit; a horizontal scroll at narrow widths instead of clipping.
            ViewThatFits(in: .horizontal) {
                chipRow
                ScrollView(.horizontal, showsIndicators: false) {
                    chipRow
                }
            }
            .frame(minHeight: answerAreaHeight)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(session.selected.enumerated()), id: \.element.id) { index, piece in
                if index > 0 {
                    Text("+")
                        .font(.display(22, weight: .bold))
                        .foregroundStyle(GardenStyle.muted)
                        .accessibilityHidden(true)
                }
                Button {
                    remove(piece)
                } label: {
                    VStack(spacing: 4) {
                        Text("\(piece.value)")
                            .font(.display(26))
                            .foregroundStyle(GardenStyle.ink)
                        BeadGroup(count: piece.value, tint: GardenStyle.teal, diameter: 7, maxColumns: session.level.dotColumns)
                    }
                    .frame(minWidth: 60, minHeight: 54)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(GardenStyle.teal.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(session.isSolved)
                .accessibilityLabel("Valgt brikke \(piece.value)")
                .accessibilityHint("Trykk for å ta brikken tilbake")
                .accessibilityIdentifier("build.selected.\(piece.value)")
            }
        }
    }

    private var piecesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tallbrikker")
                .font(.garden(.title2, weight: .heavy))
                .foregroundStyle(GardenStyle.ink)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 128, maximum: 190), spacing: 13, alignment: .top)],
                spacing: 13
            ) {
                ForEach(session.availablePieces) { piece in
                    let card = Button {
                        choose(piece)
                    } label: {
                        NumberPieceCard(number: piece.value, tint: GardenStyle.teal, compact: true, columns: session.level.dotColumns)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(session.isSolved)
                    .accessibilityHint("Trykk for å legge brikken til tallet ditt")
                    .accessibilityIdentifier("build.piece.\(piece.value)")
                    // `.disabled` does not stop drags, so attach the drag only while active.
                    if session.isSolved {
                        card
                    } else {
                        card.draggable(piece.id.uuidString)
                    }
                }
            }
        }
    }

    private func choose(_ piece: NumberPiece) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.choose(piece)
        }
        respond(to: outcome)
    }

    private func drop(_ idString: String) -> Bool {
        guard let id = UUID(uuidString: idString) else { return false }
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.choose(pieceID: id)
        }
        respond(to: outcome)
        return outcome == .progress || outcome == .solved
    }

    private func remove(_ piece: NumberPiece) {
        let removed = withAnimation(Motion.spring(reduceMotion)) {
            session.remove(piece)
        }
        if removed {
            // Spoken like any other step, so the remaining amount never goes stale aloud.
            GameFeedback.react(to: .progress, feedback: session.feedback, voiceEnabled: voice)
        }
    }

    private func clearSelection() {
        withAnimation(Motion.spring(reduceMotion)) {
            session.clearSelection()
        }
        GameFeedback.react(to: .progress, feedback: "Alle brikkene er tatt tilbake.", voiceEnabled: voice)
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
            session = BuildSession(level: fixedLevel ?? .stored())
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

// MARK: - Finn tallvennen

struct PairGameView: View {
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.challengeHost) private var challenge

    @State private var session: PairSession
    private let fixedLevel: LearningLevel?

    init(level: LearningLevel? = nil) {
        fixedLevel = level
        _session = State(initialValue: PairSession(level: level ?? .stored()))
    }

    var body: some View {
        GameScaffold(
            title: "Finn tallvennen",
            subtitle: "Finn tallet som passer sammen med det første.",
            tint: GardenStyle.orange,
            creature: .butterfly,
            mood: session.isSolved ? .happy : .idle
        ) {
            WhitePanel {
                VStack(spacing: 20) {
                    Text("Hvilket tall mangler?")
                        .font(.garden(.title2, weight: .bold))
                        .foregroundStyle(GardenStyle.muted)

                    equation
                    beads
                }
                .frame(maxWidth: .infinity)
            }

            Text("Velg riktig tall")
                .font(.garden(.title2, weight: .heavy))
                .foregroundStyle(GardenStyle.ink)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150, maximum: 235), spacing: 14, alignment: .top)],
                spacing: 14
            ) {
                ForEach(session.choices, id: \.self) { choice in
                    let tried = session.triedChoices.contains(choice)
                    Button {
                        answer(choice)
                    } label: {
                        NumberPieceCard(
                            number: choice,
                            tint: GardenStyle.orange,
                            compact: true,
                            columns: session.level.dotColumns,
                            accessibilityLabel: "Tallet \(choice)",
                            isTried: tried
                        )
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .disabled(session.isSolved)
                    .accessibilityHint(tried ? "Du har prøvd dette tallet" : "Trykk for å svare \(choice)")
                    .accessibilityIdentifier("pair.choice.\(choice)")
                }
            }

            if let feedback = session.feedback {
                StatusMessage(text: feedback, isSuccess: session.isSolved)
            }

            if session.isSolved {
                BigActionButton(
                    label: "Neste oppgave",
                    symbol: "arrow.right.circle.fill",
                    tint: GardenStyle.orange,
                    identifier: "game.next",
                    hint: "Lager et nytt regnestykke",
                    sound: .paper,
                    action: startNewPuzzle
                )
            } else {
                SecondaryActionButton(
                    label: "Les opp oppgaven",
                    symbol: "speaker.wave.2.fill",
                    tint: GardenStyle.orange,
                    identifier: "game.readPrompt",
                    action: readPromptAloud
                )
            }
        }
        .onAppear(perform: speakPromptIfEnabled)
    }

    /// One VoiceOver element: "18 pluss hvilket tall er 40", not five fragments.
    private var equation: some View {
        HStack(spacing: 13) {
            equationNumber("\(session.given)", tint: GardenStyle.orange)
            equationSign("+")
            equationNumber(session.isSolved ? "\(session.answer)" : "?", tint: GardenStyle.teal)
            equationSign("=")
            equationNumber("\(session.target)", tint: GardenStyle.purple)
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(session.spokenEquation)
        .accessibilityIdentifier("pair.equation")
    }

    private var beads: some View {
        VStack(spacing: 10) {
            if session.isSolved {
                BeadGroup(
                    segments: [
                        .init(count: session.given, tint: GardenStyle.orange),
                        .init(count: session.answer, tint: GardenStyle.teal),
                    ],
                    diameter: 18,
                    maxColumns: session.level.dotColumns
                )
                Text("\(session.given) og \(session.answer) er \(session.target) til sammen.")
                    .font(.garden(.subheadline, weight: .semibold))
                    .foregroundStyle(GardenStyle.muted)
            } else {
                BeadGroup(
                    count: session.given,
                    tint: GardenStyle.orange,
                    diameter: 18,
                    maxColumns: session.level.dotColumns,
                    placeholders: session.answer
                )
                Text("Tell de tomme plassene.")
                    .font(.garden(.subheadline, weight: .semibold))
                    .foregroundStyle(GardenStyle.muted)
            }
        }
    }

    private func equationNumber(_ value: String, tint: Color) -> some View {
        Text(value)
            .font(.display(43))
            .foregroundStyle(tint)
            .frame(minWidth: 52)
            .contentTransition(.numericText())
    }

    private func equationSign(_ sign: String) -> some View {
        Text(sign)
            .font(.display(31))
            .foregroundStyle(GardenStyle.ink)
    }

    private func readPromptAloud() {
        NorwegianVoice.shared.say(session.prompt, enabled: true, deferToVoiceOver: false)
    }

    private func speakPromptIfEnabled() {
        NorwegianVoice.shared.say(session.prompt, enabled: voice)
    }

    private func answer(_ choice: Int) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.answer(choice)
        }
        if outcome == .solved {
            solvedTotal += 1
        }
        challenge?.report(outcome)
        GameFeedback.react(to: outcome, feedback: session.feedback, voiceEnabled: voice)
    }

    private func startNewPuzzle() {
        withAnimation(Motion.quick(reduceMotion)) {
            session = PairSession(level: fixedLevel ?? .stored())
        }
        speakPromptIfEnabled()
    }
}

// MARK: - Del opp

struct SplitGameView: View {
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.challengeHost) private var challenge

    @State private var session: SplitSession
    private let fixedLevel: LearningLevel?

    init(level: LearningLevel? = nil) {
        fixedLevel = level
        _session = State(initialValue: SplitSession(level: level ?? .stored()))
    }

    var body: some View {
        GameScaffold(
            title: "Del opp",
            subtitle: "Alle prikkene skal være med, men de skal fordeles i to grupper.",
            tint: GardenStyle.purple,
            creature: .bee,
            // Attentive once the child has moved a group; a wrong check changes nothing.
            mood: session.isSolved ? .happy : (session.left == session.puzzle.startingLeft ? .idle : .thinking)
        ) {
            WhitePanel {
                VStack(spacing: 20) {
                    Text(GameCopy.splitTotal(session.total))
                        .font(.display(25))
                        .foregroundStyle(GardenStyle.ink)
                        .accessibilityIdentifier("split.total")

                    Text(GameCopy.splitWanted(session.wantedLeft))
                        .font(.garden(.title3, weight: .bold))
                        .foregroundStyle(GardenStyle.purple)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("split.wanted")

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 18) {
                            splitGroup(number: session.left, tint: GardenStyle.teal, title: "Venstre", identifier: "split.left")
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(GardenStyle.muted)
                                .padding(.top, 56)
                                .accessibilityHidden(true)
                            splitGroup(number: session.right, tint: GardenStyle.orange, title: "Høyre", identifier: "split.right")
                        }
                        .frame(minWidth: 2 * (BeadGroup.width(forCount: session.level.dotColumns, diameter: 17, maxColumns: session.level.dotColumns) + 48) + 60)
                        VStack(spacing: 14) {
                            splitGroup(number: session.left, tint: GardenStyle.teal, title: "Venstre", identifier: "split.left")
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(GardenStyle.muted)
                                .accessibilityHidden(true)
                            splitGroup(number: session.right, tint: GardenStyle.orange, title: "Høyre", identifier: "split.right")
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Text("\(session.left) + \(session.right) = \(session.total)")
                        .font(.display(31))
                        .monospacedDigit()
                        .foregroundStyle(GardenStyle.ink)
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(session.left) pluss \(session.right) er \(session.total)")
                        .accessibilityIdentifier("split.equation")

                    Slider(
                        value: Binding(
                            get: { Double(session.left) },
                            set: { setLeft(Int($0.rounded())) }
                        ),
                        in: Double(session.leftRange.lowerBound)...Double(session.leftRange.upperBound),
                        step: 1
                    )
                    .tint(GardenStyle.purple)
                    .disabled(session.isSolved)
                    .accessibilityLabel("Velg hvor mange prikker som skal være til venstre")
                    .accessibilityValue("\(session.left) til venstre og \(session.right) til høyre")
                    .accessibilityIdentifier("split.slider")

                    HStack(spacing: 16) {
                        StepButton(
                            symbol: "minus.circle.fill",
                            title: "Én mindre",
                            tint: GardenStyle.purple,
                            isEnabled: session.canDecrease,
                            accessibilityLabel: "Én mindre til venstre",
                            identifier: "split.decrease"
                        ) {
                            adjust { $0.decrease() }
                        }

                        StepButton(
                            symbol: "plus.circle.fill",
                            title: "Én mer",
                            tint: GardenStyle.purple,
                            isEnabled: session.canIncrease,
                            accessibilityLabel: "Én mer til venstre",
                            identifier: "split.increase"
                        ) {
                            adjust { $0.increase() }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if let feedback = session.feedback {
                StatusMessage(text: feedback, isSuccess: session.isSolved)
            }

            if session.isSolved {
                BigActionButton(
                    label: "Neste oppgave",
                    symbol: "arrow.right.circle.fill",
                    tint: GardenStyle.purple,
                    identifier: "game.next",
                    hint: "Lager en ny oppgave",
                    sound: .paper,
                    action: startNewPuzzle
                )
            } else {
                BigActionButton(
                    label: "Sjekk svaret",
                    symbol: "checkmark.circle.fill",
                    tint: GardenStyle.purple,
                    identifier: "split.check",
                    hint: "Sjekker om gruppene stemmer",
                    action: check
                )
                SecondaryActionButton(
                    label: "Les opp oppgaven",
                    symbol: "speaker.wave.2.fill",
                    tint: GardenStyle.purple,
                    identifier: "game.readPrompt",
                    action: readPromptAloud
                )
            }
        }
        .onAppear(perform: speakPromptIfEnabled)
    }

    private func splitGroup(number: Int, tint: Color, title: String, identifier: String) -> some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.garden(.body, weight: .bold))
                .foregroundStyle(GardenStyle.muted)
                .accessibilityHidden(true)

            // One VoiceOver element per group: "Venstre: 12 prikker".
            Text("\(number)")
                .font(.display(43))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .accessibilityLabel("\(title): \(GameCopy.dots(number))")
                .accessibilityIdentifier(identifier)

            BeadGroup(count: number, tint: tint, diameter: 17, maxColumns: session.level.dotColumns)
                .frame(
                    minHeight: BeadGroup.height(forCount: session.total - 1, diameter: 17, maxColumns: session.level.dotColumns),
                    alignment: .top
                )
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 22))
    }

    private func setLeft(_ value: Int) {
        guard value != session.left else { return }
        withAnimation(Motion.quick(reduceMotion)) {
            session.setLeft(value)
        }
        // One tick per step of the slider, like a notch; a fast drag is thinned out.
        SoundCuePlayer.shared.play(.tick, enabled: voice)
    }

    private func adjust(_ change: (inout SplitSession) -> Void) {
        withAnimation(Motion.quick(reduceMotion)) {
            change(&session)
        }
        TouchFeedback.light()
        SoundCuePlayer.shared.play(.tick, enabled: voice)
        // The amount lives in another element, so VoiceOver users hear the result here.
        VoiceOverAnnouncer.announce(session.spokenState)
    }

    private func readPromptAloud() {
        NorwegianVoice.shared.say(session.prompt, enabled: true, deferToVoiceOver: false)
    }

    private func speakPromptIfEnabled() {
        NorwegianVoice.shared.say(session.prompt, enabled: voice)
    }

    private func check() {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.check()
        }
        if outcome == .solved {
            solvedTotal += 1
        }
        challenge?.report(outcome)
        GameFeedback.react(to: outcome, feedback: session.feedback, voiceEnabled: voice)
    }

    private func startNewPuzzle() {
        withAnimation(Motion.quick(reduceMotion)) {
            session = SplitSession(level: fixedLevel ?? .stored())
        }
        speakPromptIfEnabled()
    }
}

// MARK: - Tallverkstedet

struct WorkshopView: View {
    @AppStorage(StorageKey.learningLevel) private var storedLevel = LearningLevel.fallback.rawValue
    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session = WorkshopSession(level: .stored())

    var body: some View {
        GameScaffold(
            title: "Tallverkstedet",
            subtitle: "Utforsk tall på din egen måte. Det finnes ingen feil svar.",
            tint: GardenStyle.blue,
            creature: .hedgehog,
            // A tiny, reward-free nod when the biggest total is reached; it sniffs on every change.
            mood: session.total == session.maximum ? .happy : .idle,
            progress: Double(session.total) / Double(max(session.maximum, 1))
        ) {
            // Two columns where they fit (every full-screen iPad), stacked at compact widths.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    workshopGroups
                }
                .frame(minWidth: 2 * (BeadGroup.width(forCount: session.dotColumns, diameter: 18, maxColumns: session.dotColumns) + 48) + 18)
                VStack(spacing: 18) {
                    workshopGroups
                }
            }

            WhitePanel {
                VStack(spacing: 16) {
                    Text("Sammen blir det")
                        .font(.garden(.title3, weight: .semibold))
                        .foregroundStyle(GardenStyle.muted)

                    Text(session.equation)
                        .font(.display(45))
                        .foregroundStyle(GardenStyle.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .accessibilityLabel(session.spokenEquation)
                        .accessibilityIdentifier("workshop.equation")

                    BeadGroup(
                        segments: [
                            .init(count: session.first, tint: GardenStyle.teal),
                            .init(count: session.second, tint: GardenStyle.orange),
                        ],
                        diameter: 18,
                        maxColumns: session.dotColumns
                    )
                    .frame(
                        minHeight: BeadGroup.height(forCount: session.maximum, diameter: 18, maxColumns: session.dotColumns),
                        alignment: .top
                    )
                }
                .frame(maxWidth: .infinity)
            }

            BigActionButton(
                label: "Les opp regnestykket",
                symbol: "speaker.wave.2.fill",
                tint: GardenStyle.blue,
                identifier: "workshop.speak",
                hint: "Leser regnestykket høyt på norsk"
            ) {
                // Explicit request from the child: speaks even when automatic feedback is off
                // and even while VoiceOver is running.
                NorwegianVoice.shared.say(session.spokenEquation, enabled: true, deferToVoiceOver: false)
            }

            Text(GameCopy.workshopInstruction(maximum: session.maximum))
                .font(.garden(.subheadline))
                .foregroundStyle(GardenStyle.muted)
                .padding(.horizontal, 4)
                .accessibilityIdentifier("workshop.instruction")
        }
        .onAppear {
            applyStoredLevel()
            NorwegianVoice.shared.say(GameCopy.workshopPrompt, enabled: voice)
        }
        .onChange(of: storedLevel, applyStoredLevel)
    }

    @ViewBuilder
    private var workshopGroups: some View {
        WorkshopGroup(
            name: "Første tall",
            spokenName: "det første tallet",
            number: session.first,
            largestNumber: session.maximum - 1,
            columns: session.dotColumns,
            tint: GardenStyle.teal,
            canDecrease: session.canDecreaseFirst,
            canIncrease: session.canIncrease,
            identifierPrefix: "workshop.first",
            onDecrease: { change { $0.decreaseFirst() } },
            onIncrease: { change { $0.increaseFirst() } }
        )

        WorkshopGroup(
            name: "Andre tall",
            spokenName: "det andre tallet",
            number: session.second,
            largestNumber: session.maximum - 1,
            columns: session.dotColumns,
            tint: GardenStyle.orange,
            canDecrease: session.canDecreaseSecond,
            canIncrease: session.canIncrease,
            identifierPrefix: "workshop.second",
            onDecrease: { change { $0.decreaseSecond() } },
            onIncrease: { change { $0.increaseSecond() } }
        )
    }

    private func change(_ mutation: (inout WorkshopSession) -> Void) {
        withAnimation(Motion.quick(reduceMotion)) {
            mutation(&session)
        }
        TouchFeedback.light()
        SoundCuePlayer.shared.play(.tick, enabled: voice)
        VoiceOverAnnouncer.announce(session.spokenEquation)
    }

    private func applyStoredLevel() {
        let maximum = LearningLevel.resolve(storedLevel).maximum
        if maximum != session.maximum {
            session.updateMaximum(maximum)
        }
    }
}

private struct WorkshopGroup: View {
    let name: String
    /// Definite form for spoken sentences: "fra det første tallet".
    let spokenName: String
    let number: Int
    /// Largest amount this group can show at the current level; reserves stable space.
    let largestNumber: Int
    let columns: Int
    let tint: Color
    let canDecrease: Bool
    let canIncrease: Bool
    let identifierPrefix: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        WhitePanel {
            VStack(spacing: 14) {
                Text(name)
                    .font(.garden(.body, weight: .bold))
                    .foregroundStyle(GardenStyle.muted)
                    .accessibilityHidden(true)

                // One VoiceOver element per amount: "Første tall: 3 prikker".
                Text("\(number)")
                    .font(.display(56))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(name): \(GameCopy.dots(number))")
                    .accessibilityIdentifier("\(identifierPrefix).value")

                BeadGroup(count: number, tint: tint, diameter: 18, maxColumns: columns)
                    .frame(minHeight: BeadGroup.height(forCount: largestNumber, diameter: 18, maxColumns: columns), alignment: .top)
                    .accessibilityHidden(true)

                HStack(spacing: 15) {
                    StepButton(
                        symbol: "minus",
                        tint: tint,
                        isEnabled: canDecrease,
                        accessibilityLabel: "Ta bort én fra \(spokenName)",
                        identifier: "\(identifierPrefix).decrease",
                        action: onDecrease
                    )
                    StepButton(
                        symbol: "plus",
                        tint: tint,
                        isEnabled: canIncrease,
                        accessibilityLabel: "Legg til én på \(spokenName)",
                        identifier: "\(identifierPrefix).increase",
                        action: onIncrease
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
