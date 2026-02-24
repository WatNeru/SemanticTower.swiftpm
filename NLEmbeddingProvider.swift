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
        embedding?.vector(for: word)
    }

    func similarity(between lhs: String, and rhs: String) -> Double? {
        embedding?.similarity(between: lhs, and: rhs)
    }
}

