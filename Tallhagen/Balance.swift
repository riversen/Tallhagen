import SwiftUI

// Likevekt: the equation-balance activity. A two-sided board with a central post; the hidden
// number is a closed flower bud (an original garden object) that opens to show its number when
// it stands alone. Positive cards are warm filled tiles, inverse cards are cool dashed tiles with
// a minus. Every card the child adds goes on the left and its mirror on the right (the mirror
// is a translucent dashed ghost for a moment, then solid). An inverse card is seen arriving next
// to the cards it takes away, and the pair vanishes with a small "0" puff. In the symbolic phase
// a division rail under the board splits both sides into equal parts. The three phases scaffold
// from pictures (dots only) through pictures with numerals and signs to symbols. Rules live in
// MathLogic.swift (`BalanceRules`, `BalancePuzzle`), the state in GameSessions.swift
// (`BalanceSession`); amounts on the board are never negative.

enum BalanceStyle {
    static let positive = GardenStyle.orange
    static let positiveDeep = GardenStyle.orangeDeep
    static let inverse = GardenStyle.blue
    static let bud = GardenStyle.lilac
    static let budDeep = GardenStyle.purple
    /// Grid cell of one card or bud on a side.
    static let cell: CGFloat = 60
}

/// The hidden number: a closed bud that opens into a flower showing its number.
struct BudView: View {
    let isOpen: Bool
    let number: Int
    var size: CGFloat = 56

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isOpen {
                ForEach(0..<6, id: \.self) { index in
                    Ellipse()
                        .fill(BalanceStyle.bud)
                        .overlay { Ellipse().strokeBorder(BalanceStyle.budDeep.opacity(0.6), lineWidth: 1) }
                        .frame(width: size * 0.3, height: size * 0.52)
                        .offset(y: -size * 0.28)
                        .rotationEffect(.degrees(Double(index) * 60))
                }
                Circle()
                    .fill(GardenStyle.yellow)
                    .frame(width: size * 0.46, height: size * 0.46)
                Text("\(number)")
                    .font(.display(size * 0.3))
                    .foregroundStyle(GardenStyle.ink)
            } else {
                // A closed bud on a short stem with a leaf.
                Capsule()
                    .fill(GardenStyle.leaf)
                    .frame(width: size * 0.08, height: size * 0.34)
                    .offset(y: size * 0.3)
                Ellipse()
                    .fill(GardenStyle.leaf)
                    .frame(width: size * 0.26, height: size * 0.12)
                    .rotationEffect(.degrees(-35))
                    .offset(x: -size * 0.14, y: size * 0.3)
                BudShape()
                    .fill(BalanceStyle.bud)
                    .overlay { BudShape().stroke(BalanceStyle.budDeep.opacity(0.7), lineWidth: 1.5) }
                    .frame(width: size * 0.5, height: size * 0.68)
                    .offset(y: -size * 0.06)
                // Ink on the light lilac bud: full contrast.
                Text("?")
                    .font(.display(size * 0.3))
                    .foregroundStyle(GardenStyle.ink)
                    .offset(y: -size * 0.04)
            }
        }
        .frame(width: size, height: size)
        .animation(Motion.spring(reduceMotion), value: isOpen)
        .accessibilityHidden(true)
    }
}

/// A pointed bud: a teardrop drawn with two curves.
private struct BudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                      control1: CGPoint(x: rect.maxX + w * 0.1, y: rect.minY + h * 0.45),
                      control2: CGPoint(x: rect.maxX - w * 0.1, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                      control1: CGPoint(x: rect.minX + w * 0.1, y: rect.maxY),
                      control2: CGPoint(x: rect.minX - w * 0.1, y: rect.minY + h * 0.45))
        path.closeSubpath()
        return path
    }
}

/// One card on the board or in the hand: dots (pictures), dots with a numeral (hybrid) or a
/// numeral with its sign (symbols). Positive cards are warm and filled; inverse cards are cool
/// and dashed; a ghost is translucent with a dashed outline.
struct BalanceCardView: View {
    let value: Int
    let isInverse: Bool
    let phase: BalancePhase
    var isGhost = false
    var compact = false

    private var tint: Color { isInverse ? BalanceStyle.inverse : BalanceStyle.positive }
    private var side: CGFloat { compact ? 50 : 64 }

    var body: some View {
        VStack(spacing: 3) {
            if phase != .symbolic {
                BeadGroup(count: value, tint: isInverse ? BalanceStyle.inverse : BalanceStyle.positiveDeep, diameter: compact ? 5.5 : 7, maxColumns: 5)
            }
            if phase != .pictorial {
                Text(isInverse ? "−\(value)" : "+\(value)")
                    .font(.display(compact ? 16 : 21))
                    .monospacedDigit()
                    .foregroundStyle(isInverse ? BalanceStyle.inverse : BalanceStyle.positiveDeep)
            } else if isInverse {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(BalanceStyle.inverse)
            }
        }
        .frame(width: side, height: side + (phase == .hybrid ? 12 : 0))
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isInverse ? Color.white : BalanceStyle.positive.opacity(isGhost ? 0.08 : 0.16))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(tint.opacity(isGhost ? 0.6 : 1), style: StrokeStyle(lineWidth: isInverse || isGhost ? 2 : 1.5, dash: isInverse || isGhost ? [6, 4] : []))
        }
        .opacity(isGhost ? 0.55 : 1)
        .accessibilityHidden(true)
    }
}

/// An inverse card meeting the amount it takes away; shown for a moment where the pair vanishes.
/// It always shows the amount that cancelled (plus 2 and minus 2), also when a bigger card was
/// changed into smaller ones first.
private struct CancelBurst: Identifiable, Equatable {
    let id = UUID()
    let isLeft: Bool
    let value: Int
}

/// The balance activity of a map node.
struct BalanceView: View {
    let phase: BalancePhase

    @AppStorage(StorageKey.speakNorwegian) private var voice = true
    @AppStorage(StorageKey.solvedTotal) private var solvedTotal = 0
    @Environment(\.challengeHost) private var challenge
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: BalanceSession
    /// The mirror of the last plus card, drawn as a ghost for a moment.
    @State private var ghostIDs: Set<UUID> = []
    /// Inverse cards vanishing with what they took, one per side.
    @State private var bursts: [CancelBurst] = []
    /// Clears the ghost and the bursts; cancelled when a new board starts or the view goes.
    @State private var effectTask: Task<Void, Never>?

    init(phase: BalancePhase) {
        self.phase = phase
        _session = State(initialValue: BalanceSession(phase: phase))
    }

    private var tint: Color { GardenStyle.tealDeep }

    var body: some View {
        GameScaffold(
            title: "Likevekt",
            subtitle: session.goal,
            tint: tint,
            creature: .butterfly,
            mood: session.isSolved ? .happy : (session.hasStarted ? .thinking : .idle)
        ) {
            taskPanel
            board
            // The hand stays where it is when the board is solved (dimmed), so the next-task
            // button never appears under the finger that made the last move.
            hand
                .disabled(session.isSolved)
                .opacity(session.isSolved ? 0.45 : 1)
                .accessibilityHidden(session.isSolved)

            if let feedback = session.feedback {
                HStack(alignment: .top, spacing: 12) {
                    StatusMessage(text: feedback, isSuccess: session.isSolved)
                    if session.isSolved {
                        StarRow(stars: session.stars, size: 22)
                            .padding(.top, 18)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(GameCopy.stars(session.stars))
                            .accessibilityIdentifier("balance.stars")
                    }
                }
            }

            if session.isSolved {
                BigActionButton(label: "Neste oppgave", symbol: "arrow.right.circle.fill", tint: tint, identifier: "game.next", hint: "Lager en ny oppgave", sound: .paper, action: startNewPuzzle)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        readPromptButton
                        hintButton
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        readPromptButton
                        hintButton
                    }
                }
            }
        }
        .onAppear(perform: speakPromptIfEnabled)
        .onDisappear {
            effectTask?.cancel()
            effectTask = nil
        }
    }

    // MARK: Task

    private var taskPanel: some View {
        WhitePanel {
            VStack(spacing: 8) {
                Text(session.puzzle.coefficient == 1 ? "Hva gjemmer seg i knoppen?" : "Hva gjemmer seg i knoppene?")
                    .font(.garden(.title3, weight: .semibold))
                    .foregroundStyle(GardenStyle.muted)
                    .multilineTextAlignment(.center)
                // The goal in words: the bud opens when it stands alone.
                Text(session.goal)
                    .font(.garden(.subheadline, weight: .semibold))
                    .foregroundStyle(GardenStyle.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("balance.goal")
                if phase != .pictorial {
                    Text(session.symbols)
                        .font(.display(40))
                        .monospacedDigit()
                        .foregroundStyle(GardenStyle.ink)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .accessibilityLabel(session.equation)
                        .accessibilityIdentifier("balance.symbols")
                }
                Text("Trekk: \(session.moves)")
                    .font(.garden(.subheadline, weight: .bold))
                    .foregroundStyle(GardenStyle.muted)
                    .monospacedDigit()
                    .accessibilityLabel("\(GameCopy.moves(session.moves)) brukt")
                    .accessibilityIdentifier("balance.moves")
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Board

    private var board: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                side(isLeft: true)
                post
                side(isLeft: false)
            }
            // The beam the two trays rest on.
            Capsule()
                .fill(GardenStyle.soilLight)
                .overlay { Capsule().strokeBorder(GardenStyle.soil, lineWidth: 1) }
                .frame(height: 10)
                .padding(.horizontal, 12)
                .accessibilityHidden(true)
            // Boards that start with several buds keep their rail to the end, so nothing below
            // it moves when the division has been used.
            if session.puzzle.coefficient > 1 {
                rail
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(GardenStyle.lightLine, lineWidth: 1.2)
        }
    }

    private var post: some View {
        VStack(spacing: 6) {
            Text(phase == .pictorial ? " " : "=")
                .font(.display(34))
                .foregroundStyle(GardenStyle.ink)
                .frame(height: 40)
            RoundedRectangle(cornerRadius: 3)
                .fill(GardenStyle.soil)
                .frame(width: 8)
                .frame(minHeight: 60)
        }
        .frame(width: 44)
        .accessibilityHidden(true)
    }

    private func side(isLeft: Bool) -> some View {
        let cards = isLeft ? session.leftCards : session.rightCards
        let amount = isLeft ? session.left : session.right
        // Both sides use one card size, so a mirror always looks like the card it mirrors.
        let compact = max(session.leftCards.count + session.coefficient, session.rightCards.count) > 4
        return VStack(spacing: 10) {
            // Cards wrap onto new rows instead of running off the side.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: BalanceStyle.cell, maximum: BalanceStyle.cell + 12), spacing: 8)], spacing: 8) {
                if isLeft {
                    ForEach(0..<session.coefficient, id: \.self) { _ in
                        BudView(isOpen: session.isSolved, number: session.unknown, size: compact ? 48 : 56)
                    }
                }
                ForEach(cards) { card in
                    BalanceCardView(
                        value: card.value,
                        isInverse: card.isInverse,
                        phase: phase,
                        isGhost: ghostIDs.contains(card.id),
                        compact: compact
                    )
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                }
            }
            // Two rows high from the start: a side holds at most five cards (plus up to three buds),
            // so the trays, and the hand below them, keep their place between taps.
            .frame(maxWidth: .infinity, minHeight: phase == .hybrid ? 160 : 136, alignment: .top)
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill((isLeft ? BalanceStyle.bud : BalanceStyle.positive).opacity(0.08))
            }
            .overlay(alignment: .top) {
                ForEach(bursts.filter { $0.isLeft == isLeft }) { burst in
                    CancelBurstView(burst: burst, phase: phase)
                        .transition(.asymmetric(insertion: .scale(scale: 0.7).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
                }
            }
            Text(isLeft ? "Venstre" : "Høyre")
                .font(.garden(.caption, weight: .bold))
                .foregroundStyle(GardenStyle.muted)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.spring(reduceMotion), value: cards.map(\.id))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sideLabel(isLeft: isLeft, amount: amount))
        .accessibilityIdentifier(isLeft ? "balance.left" : "balance.right")
    }

    private func sideLabel(isLeft: Bool, amount: Int) -> String {
        if isLeft {
            let buds = session.coefficient == 1 ? "knoppen" : "\(session.coefficient) knopper"
            return amount == 0 ? "Venstre side: \(buds)" : "Venstre side: \(buds) og \(amount)"
        }
        return "Høyre side: \(amount)"
    }

    /// The division rail under both sides: one button for the number of buds; dimmed once it
    /// has been used.
    private var rail: some View {
        let divisor = session.availableDivisors.first ?? session.puzzle.coefficient
        let isAvailable = !session.availableDivisors.isEmpty && !session.isSolved
        return Button {
            divide(by: divisor)
        } label: {
            Label("Del i \(divisor)", systemImage: "divide")
                .font(.garden(.body, weight: .bold))
                .foregroundStyle(tint)
                .padding(.horizontal, 20)
                .frame(minHeight: 50)
                .background(.white, in: Capsule())
                .overlay { Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1.5) }
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.45)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(alignment: .center) {
            Rectangle()
                .fill(GardenStyle.lightLine)
                .frame(height: 3)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Del begge sidene i \(divisor) like deler")
        .accessibilityIdentifier("balance.divide.\(divisor)")
    }

    // MARK: Hand

    /// The cards the child can add: warm positive cards above, cool inverse cards below.
    private var hand: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kort til begge sider")
                .font(.garden(.subheadline, weight: .bold))
                .foregroundStyle(GardenStyle.muted)
                .accessibilityAddTraits(.isHeader)
            ForEach([false, true], id: \.self) { inverse in
                HStack(spacing: 10) {
                    ForEach(BalanceRules.cardValues, id: \.self) { value in
                        Button {
                            add(value: value, inverse: inverse)
                        } label: {
                            BalanceCardView(value: value, isInverse: inverse, phase: phase)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityLabel(inverse ? "Minus \(value)" : "Pluss \(value)")
                        .accessibilityHint("Legger kortet på begge sider")
                        .accessibilityIdentifier("balance.card.\(inverse ? "minus" : "plus").\(value)")
                    }
                }
            }
        }
    }

    // MARK: Buttons

    private var readPromptButton: some View {
        SecondaryActionButton(label: "Les opp oppgaven", symbol: "speaker.wave.2.fill", tint: tint, identifier: "game.readPrompt", action: readPromptAloud)
    }

    private var hintButton: some View {
        SecondaryActionButton(label: "Få et hint", symbol: "lightbulb.fill", tint: tint, identifier: "balance.hint", action: showHint)
    }

    // MARK: Actions

    private func add(value: Int, inverse: Bool) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.add(value: value, inverse: inverse)
        }
        if outcome == .progress || outcome == .solved, !reduceMotion, let effect = session.lastEffect {
            if inverse {
                // The inverse card is seen next to what it took, then the pair vanishes.
                withAnimation(Motion.quick(reduceMotion)) {
                    bursts = [CancelBurst(isLeft: true, value: value), CancelBurst(isLeft: false, value: value)]
                }
            } else if let mirror = effect.rightCard {
                ghostIDs = [mirror.id]
            }
            scheduleEffectsEnd()
        }
        finish(outcome)
    }

    private func divide(by divisor: Int) {
        let outcome = withAnimation(Motion.spring(reduceMotion)) {
            session.divide(by: divisor)
        }
        finish(outcome)
    }

    /// Ends the ghost and the bursts after a moment, unless a new board or a new move came first.
    private func scheduleEffectsEnd() {
        effectTask?.cancel()
        effectTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                ghostIDs = []
                bursts = []
            }
        }
    }

    private func finish(_ outcome: AnswerOutcome) {
        guard outcome != .ignored else { return }
        if outcome == .solved {
            solvedTotal += 1
        }
        // A refused card or division costs nothing; a solved board counts one mistake per missing
        // star (`BalanceSession.challengeReports`).
        for report in session.challengeReports(for: outcome) {
            challenge?.report(report)
        }
        // VoiceOver also hears the new board after a move (the picture phase writes no amounts).
        var sentence = session.feedback
        if outcome == .progress, UIAccessibility.isVoiceOverRunning, let feedback = sentence {
            sentence = feedback + " Vekten viser nå: " + session.equation + "."
        }
        GameFeedback.react(to: outcome, feedback: sentence, voiceEnabled: voice)
    }

    private func showHint() {
        session.showHint()
        if let feedback = session.feedback {
            VoiceOverAnnouncer.announce(feedback)
            NorwegianVoice.shared.say(feedback, enabled: voice)
        }
    }

    private func readPromptAloud() {
        NorwegianVoice.shared.say(session.prompt + " " + session.equation + ".", enabled: true, deferToVoiceOver: false)
    }

    private func speakPromptIfEnabled() {
        NorwegianVoice.shared.say(session.prompt + " " + session.equation + ".", enabled: voice)
    }

    private func startNewPuzzle() {
        effectTask?.cancel()
        effectTask = nil
        withAnimation(Motion.quick(reduceMotion)) {
            session = BalanceSession(phase: phase)
            ghostIDs = []
            bursts = []
        }
        speakPromptIfEnabled()
    }
}

/// The amount and the inverse card that took it, side by side with "= 0" (no numeral with pictures),
/// in a small white capsule above the side; it fades upwards when the ghost time is over.
private struct CancelBurstView: View {
    let burst: CancelBurst
    let phase: BalancePhase

    var body: some View {
        HStack(spacing: 6) {
            BalanceCardView(value: burst.value, isInverse: false, phase: phase, compact: true)
            BalanceCardView(value: burst.value, isInverse: true, phase: phase, compact: true)
            if phase != .pictorial {
                Text("= 0")
                    .font(.display(22))
                    .foregroundStyle(GardenStyle.ink)
            }
        }
        .padding(8)
        .background(.white.opacity(0.95), in: Capsule())
        .overlay { Capsule().strokeBorder(BalanceStyle.inverse.opacity(0.4), lineWidth: 1.5) }
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .offset(y: -12)
        .accessibilityHidden(true)
    }
}
