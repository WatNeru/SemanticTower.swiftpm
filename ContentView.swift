import SwiftUI

struct ContentView: View {
    @StateObject private var controller = SemanticGameController()

    var body: some View {
        ZStack {
            GameView3D(scene3D: controller.scene3D)

            // 上部: タイトル・スコア（Liquid Glass / マテリアル風パネル）
            VStack(spacing: 0) {
                GlassPanel {
                    VStack(spacing: 8) {
                        Text("Semantic Tower Battle")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Text(controller.isDemoMode ? "Demo mode: preset words" : inputModeLabel)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let score = controller.lastScore, let word = controller.lastScoredWord {
                            Text("\(rankLabelText(from: score.rank)): \"\(word)\" (\(Int(score.accuracy * 100))%)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)

                Spacer()
            }

            // 下部: 入力・操作（一体化ガラスパネル）
            VStack {
                Spacer()
                inputArea
            }
        }
        .onAppear {
            SemanticDemoRunner.run()
        }
        .sensoryFeedbackForScore(controller.lastScore)
    }

    private var inputModeLabel: String {
        switch controller.inputMode {
        case .keyboard: return "Manual: type any word"
        case .handwriting: return "Manual: draw with Pencil or finger"
        }
    }

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 12) {
            // 入力モード切り替え
            if !controller.isDemoMode {
                Picker("Input", selection: $controller.inputMode) {
                    ForEach(InputMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            switch controller.inputMode {
            case .keyboard:
                keyboardInputRow
            case .handwriting:
                handwritingInputArea
            }
        }
        .padding(16)
        .glassEffect(.regular, cornerRadius: 20)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var keyboardInputRow: some View {
        HStack(spacing: 12) {
            TextField("type a word…", text: $controller.wordInput)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundStyle(.primary)
                .disabled(controller.isDemoMode)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity)

            actionButtons
        }
    }

    private var handwritingInputArea: some View {
        VStack(spacing: 10) {
            // 手書きキャンバス（仕様: iPad 画面下部に Apple Pencil / 指で記述）
            HandwritingCanvasView(
                drawing: $controller.handwritingDrawing,
                canvasSize: CGSize(width: 340, height: 80)
            )
            .frame(height: 80)
            .background(Color.white.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(controller.isDemoMode)

            if let rec = controller.lastRecognitionResult, !rec.text.isEmpty {
                // 認識結果を赤ハイライト付きで表示（仕様: 認識されなかった文字を赤く表示）
                RecognizedTextFeedbackView(result: rec)
                    .font(.subheadline.monospaced())
            }

            if let err = controller.recognitionError {
                Text(err)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button {
                    controller.clearHandwriting()
                } label: {
                    Image(systemName: "eraser")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.glass)
                .disabled(controller.isDemoMode)

                actionButtons
            }
        }
    }

    private var actionButtons: some View {
        Group {
            Button {
                if controller.isDemoMode {
                    controller.dropCurrentWord()
                } else if controller.inputMode == .handwriting {
                    Task { @MainActor in await controller.recognizeAndDrop() }
                } else {
                    controller.dropCurrentWord()
                }
            } label: {
                HStack(spacing: 6) {
                    if controller.isRecognizing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.primary)
                    } else {
                        Text("Drop")
                            .fontWeight(.semibold)
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .disabled(!controller.isDemoMode && (controller.isRecognizing || (controller.inputMode == .handwriting && controller.handwritingDrawing.bounds.isEmpty)))

            Button {
                controller.isDemoMode.toggle()
            } label: {
                Text(controller.isDemoMode ? "Demo" : "Manual")
                    .font(.footnote.weight(.semibold))
            }
            .buttonStyle(.glass)
        }
    }

    private func rankLabelText(from rankAny: Any) -> String {
        let raw = String(describing: rankAny).lowercased()
        if raw.contains("perfect") { return "Perfect" }
        if raw.contains("nice") { return "Nice" }
        if raw.contains("miss") { return "Try again" }
        return raw.capitalized
    }
}

// MARK: - 認識結果のフィードバック表示（赤文字で不明瞭な文字を表示）

struct RecognizedTextFeedbackView: View {
    let result: RecognitionResult

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(result.text.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .foregroundStyle(result.uncertainCharacterIndices.contains(index) ? .red : .primary)
                    .fontWeight(result.uncertainCharacterIndices.contains(index) ? .bold : .regular)
            }
        }
    }
}

// MARK: - スコアに応じた sensoryFeedback（iOS 17+）/ HapticFeedback（iOS 16）

private extension View {
    @ViewBuilder
    func sensoryFeedbackForScore(_ score: ScoreResult?) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(trigger: score) { old, new in
                guard let s = new else { return nil }
                switch s.rank {
                case .perfect: return .success
                case .nice: return .warning
                case .miss: return .error
                }
            }
        } else {
            self.onChange(of: score?.rank) { newRank in
                if let r = newRank { HapticFeedback.play(for: r) }
            }
        }
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
