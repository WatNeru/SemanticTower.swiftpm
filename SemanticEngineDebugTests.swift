import Foundation
import CoreGraphics

#if DEBUG

/// 簡易的なデバッグ用テスト群。
/// SwiftPM の正式なテストターゲットではないが、アプリ起動時などに呼び出して
/// ロジックの健全性を確認できる。
enum SemanticEngineDebugTests {
    static func runAll() {
        testQuadrantMapping()
        testCounterWordsOrdering()
    }

    /// アンカーと単語ベクトルを人工的に定義し、
    /// 期待する象限にマッピングされるかをざっくり検証する。
    private static func testQuadrantMapping() {
        let vectors: [String: [Double]] = [
            // アンカー
            "nature": [1, 0],
            "machine": [-1, 0],
            "human": [0, 1],
            "object": [0, -1],
            // テスト対象
            "tree": [1, 0.5],
            "robot": [-1, 0.5]
        ]

        let provider = TestEmbeddingProvider(vectors: vectors)
        let anchors = AnchorSet(
            natureWord: "nature",
            mechanicWord: "machine",
            livingWord: "human",
            objectWord: "object"
        )
        let manager = SemanticEmbeddingManager(
            provider: provider,
            config: SemanticConfig(defaultAnchors: anchors, candidateWords: ["tree", "robot"])
        )

        if let treePos = manager.calculatePosition(for: "tree") {
            assert(treePos.x > 0, "tree は Nature 寄りのはず")
            assert(treePos.y > 0, "tree は Living 寄りのはず")
        }

        if let robotPos = manager.calculatePosition(for: "robot") {
            assert(robotPos.x < 0, "robot は Mechanic 寄りのはず")
            assert(robotPos.y > 0, "robot は Living 寄りのはず")
        }
    }

    /// currentBalance の反対方向に近い語が優先されるかをざっくり検証。
    private static func testCounterWordsOrdering() {
        let vectors: [String: [Double]] = [
            // アンカー
            "nature": [1, 0],
            "machine": [-1, 0],
            "human": [0, 1],
            "object": [0, -1],
            // テスト対象
            "left": [-1, 0],
            "right": [1, 0]
        ]

        let provider = TestEmbeddingProvider(vectors: vectors)
        let anchors = AnchorSet(
            natureWord: "nature",
            mechanicWord: "machine",
            livingWord: "human",
            objectWord: "object"
        )

        let manager = SemanticEmbeddingManager(
            provider: provider,
            config: SemanticConfig(defaultAnchors: anchors, candidateWords: ["left", "right"])
        )

        // currentBalance が右方向なら、カウンターは左方向（"left"）が先頭に来るはず。
        let currentBalance = CGPoint(x: 1, y: 0)
        let result = manager.findCounterWords(currentBalance: currentBalance, candidates: nil, limit: 2)

        if let first = result.first {
            assert(first == "left", "右への重心に対するカウンター語は left が優先されるべき")
        }
    }
}

#endif

