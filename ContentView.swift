import SwiftUI

struct ContentView: View {
    @State private var controller: SemanticGameController?

    var body: some View {
        Group {
            if let controller = controller {
                GameContentView(controller: controller)
            } else {
                LoadingView()
            }
        }
        .task {
            guard controller == nil else { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
            let newController = SemanticGameController()
            controller = newController
        }
        .onAppear {
            Task.detached(priority: .utility) {
                SemanticDemoRunner.run()
            }
        }
    }
}

// MARK: - Loading Screen (cosmic theme)

private struct LoadingView: View {
    @State private var pulseScale: CGFloat = 0.8
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    STTheme.Colors.accentCyan,
                                    STTheme.Colors.nebulaPurple,
                                    STTheme.Colors.accentCyan
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotation))

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(STTheme.Colors.accentCyan)
                        .scaleEffect(pulseScale)
                }

                VStack(spacing: 8) {
                    Text("Semantic Tower")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(STTheme.Colors.textPrimary)

                    Text("Loading semantic engine…")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(STTheme.Colors.textTertiary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Game Main Content

private struct GameContentView: View {
    @ObservedObject var controller: SemanticGameController
    @StateObject private var settings = GameSettings()
    @State private var feedbackID = UUID()
    @State private var showDropFeedback = false
    @State private var lastDroppedWord: String = ""
    @State private var showSettings = false

    var body: some View {
        ZStack {
            GameView3D(scene3D: controller.scene3D)

            overlayGradient

            VStack(spacing: 0) {
                headerHUD
                    .padding(.top, 50)

                Spacer()

                feedbackOverlay

                Spacer()

                VStack(spacing: 8) {
                    compassRow

                    inputArea
                }
                .padding(.bottom, 28)
            }
        }
        .sensoryFeedbackForScore(controller.lastScore)
    }

    // MARK: - Gradient overlay

    private var overlayGradient: some View {
        let boost: Double = settings.highContrast ? 0.25 : 0
        return VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    STTheme.Colors.cosmicDeep.opacity(0.65 + boost),
                    STTheme.Colors.cosmicDeep.opacity(0.25 + boost),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)

            Spacer()

            LinearGradient(
                colors: [
                    Color.clear,
                    STTheme.Colors.cosmicDeep.opacity(0.35 + boost),
                    STTheme.Colors.cosmicDeep.opacity(0.75 + boost)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Header HUD

    private var headerHUD: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(STTheme.Colors.textTertiary)
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView(settings: settings)
                    }

                    Button {
                        controller.resetGame()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13))
                            .foregroundColor(STTheme.Colors.textTertiary)
                    }

                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(STTheme.Colors.accentCyan)

                    Text("Semantic Tower")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(STTheme.Colors.textPrimary)
                }

                Text(modeLabel)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(STTheme.Colors.textTertiary)

                if let score = controller.lastScore, let word = controller.lastScoredWord {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(rankColor(score.rank))
                            .frame(width: 6, height: 6)
                        Text("\(rankLabel(score.rank)): \"\(word)\" (\(Int(score.accuracy * 100))%)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(STTheme.Colors.textSecondary)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16, opacity: 0.10)

            Spacer()

            VStack(spacing: 8) {
                BalanceIndicator(
                    centerOfMass: controller.scene3D.currentCenterOfMass,
                    discCount: controller.scene3D.activeDiscCount
                )

                GameStatsView(
                    discCount: controller.scene3D.activeDiscCount,
                    towerHeight: controller.scene3D.towerHeight,
                    perfectStreak: controller.perfectStreak,
                    isBalanced: isBalanced(controller.scene3D.currentCenterOfMass),
                    fallCount: controller.fallCount
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private func isBalanced(_ center: CGPoint) -> Bool {
        hypot(center.x, center.y) < 0.4
    }

    private var modeLabel: String {
        switch controller.inputMode {
        case .keyboard: return "Type any word"
        case .handwriting: return "Draw any word"
        }
    }

    // MARK: - Compass row

    private var compassRow: some View {
        HStack {
            Spacer()
            CompassOverlayView(controller: controller)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Input area

    private var inputArea: some View {
        VStack(spacing: 10) {
            if !controller.isDemoMode {
                Picker("Input", selection: $controller.inputMode) {
                    ForEach(InputMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 4)
            }

            if controller.isDemoMode {
                demoDropButton
            } else {
                switch controller.inputMode {
                case .keyboard:
                    keyboardInputRow
                case .handwriting:
                    handwritingInputArea
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 22, opacity: 0.12)
        .padding(.horizontal, 20)
    }

    private var demoDropButton: some View {
        Button { performDrop() } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Drop \"\(controller.nextDemoWord)\"")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(STTheme.Colors.cosmicDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(STTheme.Colors.accentGold))
            .glow(STTheme.Colors.accentGold, radius: 4)
        }
    }

    private var keyboardInputRow: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "character.cursor.ibeam")
                        .foregroundColor(STTheme.Colors.textTertiary)
                        .font(.system(size: 13))

                    TextField("type a word…", text: $controller.wordInput)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(STTheme.Colors.textPrimary)
                        .onSubmit { performDrop() }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(STTheme.Colors.glassWhiteBorder, lineWidth: 0.5)
                )

                actionButtons
            }

            if let err = controller.keyboardError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(STTheme.Colors.missOrange)
                    Text(err)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(STTheme.Colors.missOrange)
                }
            }
        }
    }

    private var handwritingInputArea: some View {
        HandwritingInputPanel(
            controller: controller,
            onDrop: { performDrop() }
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                performDrop()
            } label: {
                HStack(spacing: 5) {
                    if controller.isRecognizing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(STTheme.Colors.cosmicDeep)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Drop")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(STTheme.Colors.cosmicDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(STTheme.Colors.accentCyan)
                )
                .glow(STTheme.Colors.accentCyan, radius: 4)
            }
            .disabled(isDropDisabled)
        }
    }

    private var isDropDisabled: Bool {
        if controller.isRecognizing { return true }
        if controller.inputMode == .handwriting {
            return !controller.hasHandwritingStrokes
        }
        return controller.wordInput
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func performDrop() {
        feedbackID = UUID()
        if controller.isDemoMode {
            lastDroppedWord = controller.nextDemoWord
            controller.dropDemoWord()
            showDropFeedback = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showDropFeedback = false
            }
        } else if controller.inputMode == .handwriting {
            Task { @MainActor in
                await controller.recognizeAndDrop()
            }
        } else {
            controller.dropKeyboardWord()
        }
    }

    // MARK: - Feedback overlay

    private var feedbackOverlay: some View {
        ZStack {
            if let score = controller.lastScore,
               let word = controller.lastScoredWord {
                ScoreFeedbackView(score: score, word: word)
                    .id(feedbackID)
            }

            if showDropFeedback {
                WordDropFeedback(word: lastDroppedWord)
                    .id("drop-\(lastDroppedWord)-\(feedbackID)")
                    .transition(.opacity)
            }

            if let fallen = controller.lastFallenWord {
                FallNotificationView(word: fallen, fallCount: controller.fallCount)
                    .id("fall-\(fallen)-\(controller.fallCount)")
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Helpers

    private func rankLabel(_ rank: ScoreRank) -> String {
        switch rank {
        case .perfect: return "Perfect"
        case .nice: return "Nice"
        case .miss: return "Miss"
        }
    }

    private func rankColor(_ rank: ScoreRank) -> Color {
        switch rank {
        case .perfect: return STTheme.Colors.perfectGreen
        case .nice: return STTheme.Colors.niceYellow
        case .miss: return STTheme.Colors.missRed
        }
    }
}

// MARK: - Recognition feedback (educational app style)

struct RecognizedTextFeedbackView: View {
    let result: RecognitionResult
    @State private var revealedCount = 0

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(Array(result.text.enumerated()), id: \.offset) { index, char in
                    let isUncertain = result.uncertainCharacterIndices.contains(index)
                    Text(String(char))
                        .font(.system(size: 20, weight: isUncertain ? .bold : .medium, design: .monospaced))
                        .foregroundColor(isUncertain ? STTheme.Colors.missOrange : STTheme.Colors.textPrimary)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isUncertain
                                      ? STTheme.Colors.missOrange.opacity(0.12)
                                      : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isUncertain
                                        ? STTheme.Colors.missOrange.opacity(0.3)
                                        : Color.clear,
                                        lineWidth: 1)
                        )
                        .opacity(index < revealedCount ? 1.0 : 0.0)
                        .scaleEffect(index < revealedCount ? 1.0 : 0.5)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                            value: revealedCount
                        )
                }
            }

            confidenceBar
        }
        .onAppear {
            withAnimation {
                revealedCount = result.text.count
            }
        }
    }

    private var confidenceBar: some View {
        HStack(spacing: 6) {
            Image(systemName: confidenceIcon)
                .font(.system(size: 10))
                .foregroundColor(confidenceColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(confidenceColor)
                        .frame(width: max(0, geo.size.width * result.confidence))
                }
            }
            .frame(height: 4)

            Text("\(Int(result.confidence * 100))%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(STTheme.Colors.textTertiary)
        }
        .frame(maxWidth: 180)
    }

    private var confidenceColor: Color {
        if result.confidence >= 0.8 { return STTheme.Colors.perfectBlue }
        if result.confidence >= 0.5 { return STTheme.Colors.niceGold }
        return STTheme.Colors.missOrange
    }

    private var confidenceIcon: String {
        if result.confidence >= 0.8 { return "checkmark.circle.fill" }
        if result.confidence >= 0.5 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }
}

// MARK: - Haptic feedback bridge

private extension View {
    @ViewBuilder
    func sensoryFeedbackForScore(_ score: ScoreResult?) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(trigger: score) { _, newValue in
                guard let newScore = newValue else { return nil }
                switch newScore.rank {
                case .perfect: return .success
                case .nice: return .warning
                case .miss: return .error
                }
            }
        } else {
            self.onChange(of: score?.rank) { newRank in
                if let rank = newRank { HapticFeedback.play(for: rank) }
            }
        }
    }
}

// MARK: - Demo runner

enum SemanticDemoRunner {
    static func run() {
        #if DEBUG
        SemanticEngineDebugTests.runAll()
        #endif

        let provider = NLEmbeddingProvider()

        let anchors = AnchorSet(
            natureWord: "nature",
            mechanicWord: "machine",
            livingWord: "animal",
            objectWord: "object"
        )

        let animals = ["dog", "cat", "lion", "eagle", "whale"]
        let natureWords = ["tree", "river", "mountain", "forest", "ocean"]
        let machines = ["car", "train", "airplane", "computer", "robot"]
        let objects = ["stone", "chair", "table", "phone", "book"]
        let emotions = ["happy", "sad", "angry", "calm", "excited"]
        let abstract = ["freedom", "justice", "love", "power", "idea"]

        let demoWords = animals + natureWords + machines + objects + emotions + abstract

        let config = SemanticConfig(
            defaultAnchors: anchors,
            candidateWords: demoWords,
            positionScale: 4.0
        )

        let manager = SemanticEmbeddingManager(provider: provider, config: config)

        func dumpPositions(title: String, words: [String]) {
            print("=== SemanticDemoRunner: \(title) ===")
            for word in words {
                if let base = manager.calculatePosition(for: word),
                   let scaled = manager.scaledPosition(for: word) {
                    let baseX = String(format: "%.3f", base.x)
                    let baseY = String(format: "%.3f", base.y)
                    let scaledX = String(format: "%.3f", scaled.x)
                    let scaledY = String(format: "%.3f", scaled.y)
                    print("\(word): base=(x=\(baseX), y=\(baseY)) scaled=(x=\(scaledX), y=\(scaledY))")
                } else {
                    print("\(word): position unavailable (unknown word)")
                }
            }
            print("")
        }

        dumpPositions(title: "animals (Living 寄り)", words: animals)
        dumpPositions(title: "nature (Nature 寄り)", words: natureWords)
        dumpPositions(title: "machines (Mechanic 寄り)", words: machines)
        dumpPositions(title: "objects (Object 寄り)", words: objects)
        dumpPositions(title: "emotions / abstract", words: emotions + abstract)

        let currentBalance = CGPoint(x: 0.6, y: 0.4)
        let counter = manager.findCounterWords(currentBalance: currentBalance, candidates: nil, limit: 5)
        print("=== SemanticDemoRunner: counter words for balance (\(currentBalance.x), \(currentBalance.y)) ===")
        print(counter)
    }
}
