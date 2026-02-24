import Foundation
import NaturalLanguage

/// Apple 純正の英語単語埋め込み (`NLEmbedding.wordEmbedding(for: .english)`) を
/// ラップした本番用プロバイダ。
final class NLEmbeddingProvider: SemanticEmbeddingProvider {
    private let embedding: NLEmbedding?

    init() {
        self.embedding = NLEmbedding.wordEmbedding(for: .english)
    }

    func vector(for word: String) -> [Double]? {
        guard let raw = embedding?.vector(for: word) else {
            return nil
        }
        return raw.map { Double(truncating: $0 as NSNumber) }
    }

    func similarity(between lhs: String, and rhs: String) -> Double? {
        // NLEmbedding には similarity API がないため、
        // ベクトルからコサイン類似度を自前で計算する。
        guard
            let v1 = vector(for: lhs),
            let v2 = vector(for: rhs),
            v1.count == v2.count,
            !v1.isEmpty
        else {
            return nil
        }

        var dot: Double = 0
        var len1: Double = 0
        var len2: Double = 0

        for i in 0..<v1.count {
            let a = Double(truncating: v1[i] as NSNumber)
            let b = Double(truncating: v2[i] as NSNumber)
            dot += a * b
            len1 += a * a
            len2 += b * b
        }

        let denom = sqrt(len1) * sqrt(len2)
        guard denom > 0 else { return nil }
        return dot / denom
    }
}

