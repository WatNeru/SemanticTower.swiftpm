import Foundation
import SwiftUI

/// セマンティック・エンジンと 3D シーンをつなぐ ViewModel。
final class SemanticGameController: ObservableObject {
    @Published var wordInput: String = ""
    @Published var isDemoMode: Bool = true
    @Published var lastScore: ScoreResult?
    @Published var lastScoredWord: String?

    let scene3D: GameScene3D
    private let manager: SemanticEmbeddingManager
    let demoWords: [String] = [
        "dog", "cat", "lion",
        "tree", "river", "forest",
        "car", "robot", "computer",
        "stone", "chair", "phone",
        "happy", "sad", "freedom"
    ]
    private var demoIndex: Int = 0

    /// 次にドロップされるデモ単語（UI のプレビュー表示用）。
    var nextDemoWord: String {
        guard !demoWords.isEmpty else { return "" }
        return demoWords[demoIndex % demoWords.count]
    }

    init() {
        scene3D = GameScene3D()

        let anchors = AnchorSet(
            natureWord: "nature",
            mechanicWord: "machine",
            livingWord: "animal",
            objectWord: "object"
        )

        let config = SemanticConfig(
            defaultAnchors: anchors,
            candidateWords: [],
            positionScale: 4.0
        )

        let provider = NLEmbeddingProvider()
        manager = SemanticEmbeddingManager(provider: provider, config: config)
    }

    func dropCurrentWord() {
        // デモモード時は、ハードコードされた単語を順番に使用。
        if isDemoMode {
            guard !demoWords.isEmpty else { return }
            let word = demoWords[demoIndex % demoWords.count]
            demoIndex += 1
            drop(word: word)
            return
        }

        let trimmed = wordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        drop(word: trimmed)
        wordInput = ""
    }

    private func drop(word: String) {
        let lowercased = word.lowercased()

        guard let semanticPos = manager.calculatePosition(for: lowercased) else {
            print("No embedding found for word: \(word)")
            return
        }

        // 重さは文字数ベースでざっくり設定（長い単語ほど重い）。
        let baseMass = max(0.5, min(3.0, Double(lowercased.count) / 3.0))

        let xStr = String(format: "%.3f", semanticPos.x)
        let yStr = String(format: "%.3f", semanticPos.y)
        let massStr = String(format: "%.2f", baseMass)
        print("[Drop] word=\"\(word)\", semantic=(x=\(xStr), y=\(yStr)), mass=\(massStr)")

        // セマンティック座標をそのままボード上の局所座標にマッピング。
        scene3D.addDisc(atSemanticPosition: semanticPos, color: .systemTeal, mass: baseMass)

        // 手動入力時のみスコアリング（デモモードの自動落下はスコアなし）。
        if !isDemoMode {
            let result = ScoringEngine.evaluateAccuracy(input: word, target: word)
            lastScore = result
            lastScoredWord = word
        }
    }
}

