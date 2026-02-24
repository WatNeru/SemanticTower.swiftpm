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

                        Text(controller.isDemoMode ? "Demo mode: preset words" : "Manual mode: type any word")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let score = controller.lastScore, let word = controller.lastScoredWord {
                            Text("\(rankLabelText(from: score.rank)): \"\(word)\" (accuracy: \(Int(score.accuracy * 100))%)")
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

                    Button {
                        controller.dropCurrentWord()
                    } label: {
                        Text("Drop")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.glassProminent)

                    Button {
                        controller.isDemoMode.toggle()
                    } label: {
                        Text(controller.isDemoMode ? "Demo" : "Manual")
                            .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
                .padding(16)
                .glassEffect(.regular, cornerRadius: 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            SemanticDemoRunner.run()
        }
    }

    private func rankLabelText(from rankAny: Any) -> String {
        // Fallback: derive a user-friendly label from whatever `rank` is.
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

        // カテゴリごとに代表的な単語を用意して、広い意味空間をざっと眺める。
        let animals = ["dog", "cat", "lion", "eagle", "whale"]
        let natureWords = ["tree", "river", "mountain", "forest", "ocean"]
        let machines = ["car", "train", "airplane", "computer", "robot"]
        let objects = ["stone", "chair", "table", "phone", "book"]
        let emotions = ["happy", "sad", "angry", "calm", "excited"]
        let abstract = ["freedom", "justice", "love", "power", "idea"]

        let demoWords = animals + natureWords + machines + objects + emotions + abstract

        // ゲーム用に差を少し強調したいので positionScale を 4.0 に設定。
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

// 将来、セマンティック重心に応じて GameScene3D.updateBoardTilt(centerOfMass:) を
// 呼び出すための橋渡し用として、必要に応じて ViewModel をここに追加していく予定。

