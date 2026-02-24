import Foundation

#if DEBUG

/// ユニットテストやデバッグ用のシンプルな埋め込みプロバイダ。
/// 単語ごとに決め打ちのベクトルを返し、コサイン類似度を計算する。
struct TestEmbeddingProvider: SemanticEmbeddingProvider {
    private let vectors: [String: [Double]]

    init(vectors: [String: [Double]]) {
        self.vectors = vectors
    }

    func vector(for word: String) -> [Double]? {
        vectors[word]
    }

    func similarity(between lhs: String, and rhs: String) -> Double? {
        guard
            let v1 = vectors[lhs],
            let v2 = vectors[rhs],
            v1.count == v2.count,
            !v1.isEmpty
        else {
            return nil
        }

        var dot: Double = 0
        var len1: Double = 0
        var len2: Double = 0

        for i in 0..<v1.count {
            let a = v1[i]
            let b = v2[i]
            dot += a * b
            len1 += a * a
            len2 += b * b
        }

        let denom = sqrt(len1) * sqrt(len2)
        guard denom > 0 else { return nil }
        return dot / denom
    }
}

#endif

