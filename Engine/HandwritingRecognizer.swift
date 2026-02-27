import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Vision フレームワークによる手書き・テキスト認識。
/// 仕様: 「認識されなかった文字を赤く表示」のため、文字単位の信頼度も返す。
struct RecognitionResult {
    let text: String
    /// 全体の認識信頼度 (0...1)
    let confidence: Double
    /// 認識に失敗した／信頼度が低い文字のインデックス（赤表示用）
    let uncertainCharacterIndices: Set<Int>
}

/// オンデバイス・オフラインのテキスト認識（SSC 25MB 制約準拠）
enum HandwritingRecognizer {
    /// ゲームでよく使う英単語を customWords に渡して認識精度を向上
    private static let customWords: [String] = [
        "dog", "cat", "lion", "eagle", "whale",
        "tree", "river", "mountain", "forest", "ocean",
        "car", "train", "airplane", "computer", "robot",
        "stone", "chair", "table", "phone", "book",
        "happy", "sad", "angry", "calm", "excited",
        "freedom", "justice", "love", "power", "idea",
        "nature", "machine", "animal", "object"
    ]

    /// 画像からテキストを認識（メインスレッド外で実行推奨）
    static func recognize(from image: UIImage) async -> RecognitionResult? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { (continuation: CheckedContinuation<RecognitionResult?, Never>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("[HandwritingRecognizer] Vision error: \(error)")
                    continuation.resume(returning: nil as RecognitionResult?)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil as RecognitionResult?)
                    return
                }

                var fullText = ""
                var uncertainIndices = Set<Int>()
                var totalConfidence: Double = 0
                var charCount = 0

                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }

                    let str = candidate.string
                    let conf = Double(candidate.confidence)

                    for (i, char) in str.enumerated() {
                        let idx = fullText.count + i
                        fullText += String(char)
                        totalConfidence += conf
                        charCount += 1
                        if conf < 0.7 {
                            uncertainIndices.insert(idx)
                        }
                    }
                }

                let avgConfidence = charCount > 0 ? totalConfidence / Double(charCount) : 0
                let trimmed = fullText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                // 全体信頼度が低い場合は全文字を「不明瞭」として赤表示
                let finalUncertain = avgConfidence < 0.6
                    ? Set(0..<trimmed.count)
                    : uncertainIndices
                let result = RecognitionResult(
                    text: trimmed,
                    confidence: avgConfidence,
                    uncertainCharacterIndices: finalUncertain
                )
                continuation.resume(returning: result)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            request.customWords = customWords

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("[HandwritingRecognizer] Perform error: \(error)")
                continuation.resume(returning: nil as RecognitionResult?)
            }
        }
    }
}
