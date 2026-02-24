import Foundation
import SwiftUI

/// セマンティック・エンジンと 3D シーンをつなぐ ViewModel。
final class SemanticGameController: ObservableObject {
    @Published var wordInput: String = ""

    let scene3D: GameScene3D
    private let manager: SemanticEmbeddingManager

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
        let trimmed = wordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let lowercased = trimmed.lowercased()

        guard let semanticPos = manager.calculatePosition(for: lowercased) else {
            print("No embedding found for word: \(trimmed)")
            return
        }

        // セマンティック座標をそのままボード上の局所座標にマッピング。
        scene3D.addDisc(atSemanticPosition: semanticPos, color: .systemTeal)

        wordInput = ""
    }
}

