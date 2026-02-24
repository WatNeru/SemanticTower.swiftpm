import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Semantic Tower Debug")
                .font(.title.bold())

            Text("コンソールログに単語の座標とカウンター語候補を出力します。")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            SemanticDemoRunner.run()
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

        let demoWords = ["dog", "cat", "car", "tree", "robot", "stone"]

        let config = SemanticConfig(
            defaultAnchors: anchors,
            candidateWords: demoWords
        )

        let manager = SemanticEmbeddingManager(provider: provider, config: config)

        print("=== SemanticDemoRunner: positions ===")
        for word in demoWords {
            if let pos = manager.calculatePosition(for: word) {
                print("\(word): x=\(String(format: "%.3f", pos.x)), y=\(String(format: "%.3f", pos.y))")
            } else {
                print("\(word): position unavailable (unknown word)")
            }
        }

        let currentBalance = CGPoint(x: 0.6, y: 0.4)
        let counter = manager.findCounterWords(currentBalance: currentBalance, candidates: nil, limit: 3)
        print("=== SemanticDemoRunner: counter words for balance (\(currentBalance.x), \(currentBalance.y)) ===")
        print(counter)
    }
}

