import Foundation

enum ScoreRank: Equatable {
    case perfect
    case nice
    case miss
}

struct ScoreResult: Equatable {
    let rank: ScoreRank
    let accuracy: Double
}

/// 入力とターゲット文字列の一致度を評価するシンプルなスコアリング。
/// 手書き認識時は認識信頼度をそのまま accuracy として使用。
enum ScoringEngine {
    /// 手書き認識結果からスコアを算出（仕様: 信頼度で Perfect/Nice/Miss 判定）
    static func evaluateFromRecognition(confidence: Double, uncertainCharacterCount: Int) -> ScoreResult {
        let penalty = Double(uncertainCharacterCount) * 0.1
        let accuracy = max(0, min(1, confidence - penalty))

        let rank: ScoreRank
        if accuracy >= 0.9 {
            rank = .perfect
        } else if accuracy >= 0.6 {
            rank = .nice
        } else {
            rank = .miss
        }
        return ScoreResult(rank: rank, accuracy: accuracy)
    }

    static func evaluateAccuracy(input: String, target: String) -> ScoreResult {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedInput.isEmpty || trimmedTarget.isEmpty {
            return ScoreResult(rank: .miss, accuracy: 0)
        }

        let inputChars = Array(trimmedInput.lowercased())
        let targetChars = Array(trimmedTarget.lowercased())

        let maxLength = max(inputChars.count, targetChars.count)
        guard maxLength > 0 else {
            return ScoreResult(rank: .miss, accuracy: 0)
        }

        var matches = 0
        let minLength = min(inputChars.count, targetChars.count)

        for i in 0..<minLength {
            if inputChars[i] == targetChars[i] {
                matches += 1
            }
        }

        let accuracy = Double(matches) / Double(maxLength)

        let rank: ScoreRank
        if accuracy >= 0.9 {
            rank = .perfect
        } else if accuracy >= 0.6 {
            rank = .nice
        } else {
            rank = .miss
        }

        return ScoreResult(rank: rank, accuracy: accuracy)
    }
}

