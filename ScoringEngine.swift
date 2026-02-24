import Foundation

enum ScoreRank {
    case perfect
    case nice
    case miss
}

struct ScoreResult {
    let rank: ScoreRank
    let accuracy: Double
}

/// 入力とターゲット文字列の一致度を評価するシンプルなスコアリング。
enum ScoringEngine {
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

