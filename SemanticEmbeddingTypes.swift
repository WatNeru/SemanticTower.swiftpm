import Foundation
import CoreGraphics

/// 単語からベクトルや類似度を取得するための抽象プロバイダ。
/// 実装例として `NLEmbedding` ラッパーやテスト用フェイクを想定する。
protocol SemanticEmbeddingProvider {
    /// 単語に対応する埋め込みベクトルを返す。
    /// 未知語などで取得できない場合は `nil`。
    func vector(for word: String) -> [Double]?

    /// 2つの単語間の類似度（通常はコサイン類似度）を返す。
    /// 範囲は実装に依存するが、`[-1, 1]` を想定する。
    func similarity(between lhs: String, and rhs: String) -> Double?
}

/// 意味空間上の基準となるアンカー語のセット。
/// X軸: natureWord ↔ mechanicWord
/// Y軸: livingWord ↔ objectWord
struct AnchorSet: Equatable {
    let natureWord: String
    let mechanicWord: String
    let livingWord: String
    let objectWord: String
}

/// セマンティック・エンジンの設定値。
/// - デフォルトアンカー
/// - 候補単語リスト（カウンター語探索などに利用）
/// - 物理空間などへ投影する際のスケーリング係数
struct SemanticConfig {
    let defaultAnchors: AnchorSet
    let candidateWords: [String]
    /// 画面や物理空間にマッピングする際のスケール係数。
    /// `1.0` はセマンティック座標そのまま、`3.0` などにすると差が強調される。
    let positionScale: Double

    init(
        defaultAnchors: AnchorSet = AnchorSet(
            natureWord: "nature",
            mechanicWord: "machine",
            livingWord: "human",
            objectWord: "object"
        ),
        candidateWords: [String] = [],
        positionScale: Double = 1.0
    ) {
        self.defaultAnchors = defaultAnchors
        self.candidateWords = candidateWords
        self.positionScale = positionScale
    }
}

