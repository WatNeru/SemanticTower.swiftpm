import SwiftUI

struct ContentView: View {
    @StateObject private var controller = SemanticGameController()
    @State private var feedbackID = UUID()
    @State private var showDropFeedback = false
    @State private var lastDroppedWord: String = ""

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

                bottomBar
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            SemanticDemoRunner.run()
        }
    }

    // MARK: - Top gradient overlay for readability

    private var overlayGradient: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    STTheme.Colors.cosmicDeep.opacity(0.7),
                    STTheme.Colors.cosmicDeep.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)

            Spacer()

            LinearGradient(
                colors: [
                    Color.clear,
                    STTheme.Colors.cosmicDeep.opacity(0.4),
                    STTheme.Colors.cosmicDeep.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Header HUD

    private var headerHUD: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(STTheme.Colors.accentCyan)

                    Text("Semantic Tower")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(STTheme.Colors.textPrimary)
                }

                Text(controller.isDemoMode
                     ? "Demo mode — preset words"
                     : "Manual mode — type any word")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(STTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16, opacity: 0.10)

            Spacer()

            BalanceIndicator(
                centerOfMass: controller.scene3D.currentCenterOfMass,
                discCount: controller.scene3D.activeDiscCount
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Center feedback

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
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        WordInputBar(
            text: $controller.wordInput,
            isDemoMode: controller.isDemoMode,
            onDrop: {
                let wordBeforeDrop = controller.isDemoMode
                    ? controller.nextDemoWord
                    : controller.wordInput
                controller.dropCurrentWord()
                feedbackID = UUID()

                if controller.isDemoMode {
                    lastDroppedWord = wordBeforeDrop
                    showDropFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showDropFeedback = false
                    }
                }
            },
            onToggleMode: {
                withAnimation(.spring(response: 0.3)) {
                    controller.isDemoMode.toggle()
                }
            }
        )
    }

    private func rankLabelText(from rankAny: Any) -> String {
        let raw = String(describing: rankAny).lowercased()
        if raw.contains("perfect") { return "Perfect" }
        if raw.contains("nice") { return "Nice" }
        if raw.contains("miss") { return "Try again" }
        return raw.capitalized
    }
}

/// フェーズ1のセマンティック・エンジンを検証するための簡易デモ。
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
