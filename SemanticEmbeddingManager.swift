import Foundation
import CoreGraphics

/// セマンティック・エンジンの中核となるマネージャ。
/// - 512次元の単語ベクトルを2次元座標に射影
/// - 現在の重心を打ち消す方向の「カウンター語」を探索
struct SemanticEmbeddingManager {
    private let provider: SemanticEmbeddingProvider
    private let config: SemanticConfig

    init(provider: SemanticEmbeddingProvider, config: SemanticConfig = SemanticConfig()) {
        self.provider = provider
        self.config = config
    }

    /// 与えられた単語を、アンカー語に基づく2次元座標へ射影する。
    /// - Parameters:
    ///   - word: 対象単語
    ///   - anchors: 使用するアンカーセット（省略時はデフォルト）
    /// - Returns: 正規化済み座標（`[-1, 1]` の範囲）または未知語なら `nil`
    func calculatePosition(for word: String, anchors: AnchorSet? = nil) -> CGPoint? {
        let anchorSet = anchors ?? config.defaultAnchors

        guard
            let xNature = provider.similarity(between: word, and: anchorSet.natureWord),
            let xMechanic = provider.similarity(between: word, and: anchorSet.mechanicWord),
            let yLiving = provider.similarity(between: word, and: anchorSet.livingWord),
            let yObject = provider.similarity(between: word, and: anchorSet.objectWord)
        else {
            return nil
        }

        let xRaw = xNature - xMechanic
        let yRaw = yLiving - yObject

        let xNorm = normalizeDifference(xRaw)
        let yNorm = normalizeDifference(yRaw)

        return CGPoint(x: xNorm, y: yNorm)
    }

    /// セマンティック座標を、ゲーム用などのスケーリング後座標として取得する。
    /// - Parameters:
    ///   - word: 対象単語
    ///   - anchors: 使用するアンカーセット（省略時はデフォルト）
    ///   - scale: 追加のスケール係数。未指定なら `SemanticConfig.positionScale` を使用。
    func scaledPosition(
        for word: String,
        anchors: AnchorSet? = nil,
        scale: Double? = nil
    ) -> CGPoint? {
        guard let base = calculatePosition(for: word, anchors: anchors) else {
            return nil
        }
        let factor = scale ?? config.positionScale
        return CGPoint(x: base.x * factor, y: base.y * factor)
    }

    /// 重心を立て直すための最適落下位置（セマンティック座標）を返す。
    /// 現在の重心の反対方向がターゲットとなる。
    func targetDropPosition(currentBalance: CGPoint) -> CGPoint {
        CGPoint(x: -currentBalance.x, y: -currentBalance.y)
    }

    /// 現在の重心を打ち消す方向に近い単語を、候補リストの中から探索する。
    /// - Parameters:
    ///   - currentBalance: 現在の重心ベクトル
    ///   - candidates: 探索対象の単語リスト（省略時は `SemanticConfig.candidateWords`）
    ///   - limit: 返却する最大件数
    func findCounterWords(
        currentBalance: CGPoint,
        candidates: [String]? = nil,
        limit: Int = 5
    ) -> [String] {
        let candidateWords = candidates ?? config.candidateWords
        guard !candidateWords.isEmpty else { return [] }

        // 目標方向は現在の重心の「反対向き」
        let target = CGPoint(x: -currentBalance.x, y: -currentBalance.y)
        let targetVector = CGVector(dx: target.x, dy: target.y)
        let targetLength = hypot(targetVector.dx, targetVector.dy)

        // 長さゼロ（完全バランス）の場合は、単に原点付近の単語を優先
        let useDirectionSimilarity = targetLength > 0.0001

        let scored: [(word: String, score: Double)] = candidateWords.compactMap { word -> (word: String, score: Double)? in
            guard let position = calculatePosition(for: word, anchors: nil) else {
                return nil
            }

            let candidateVector = CGVector(dx: position.x, dy: position.y)

            if useDirectionSimilarity {
                // 方向の近さ（コサイン類似度）でスコアリング
                let dot = targetVector.dx * candidateVector.dx + targetVector.dy * candidateVector.dy
                let candLength = hypot(candidateVector.dx, candidateVector.dy)
                guard candLength > 0.0001 else { return nil }
                let cosSim = dot / (targetLength * candLength)
                return (word, Double(cosSim))
            } else {
                // 原点からの距離が近いほどスコアが高いようにする
                let distance = hypot(position.x, position.y)
                let score = 1.0 - min(Double(distance), 1.0)
                return (word, score)
            }
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.word }
    }

    // MARK: - Private helpers

    /// 類似度差分（理論値はおよそ `[-2, 2]`）を `[-1, 1]` に収める。
    private func normalizeDifference(_ value: Double, maxMagnitude: Double = 2.0) -> Double {
        guard maxMagnitude > 0 else { return 0 }
        let clamped = max(-maxMagnitude, min(maxMagnitude, value))
        return clamped / maxMagnitude
    }
}

