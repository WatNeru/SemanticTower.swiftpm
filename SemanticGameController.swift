import Foundation
import SwiftUI
import PencilKit

/// 入力モード（仕様: キーボード or 手書き）
enum InputMode: String, CaseIterable {
    case keyboard = "Keyboard"
    case handwriting = "Handwriting"
}

/// セマンティック・エンジンと 3D シーンをつなぐ ViewModel。
@MainActor
final class SemanticGameController: ObservableObject {
    @Published var wordInput: String = ""
    @Published var isDemoMode: Bool = false
    @Published var inputMode: InputMode = .handwriting
    @Published var handwritingDrawing: PKDrawing = PKDrawing()
    @Published var lastScore: ScoreResult?
    @Published var lastScoredWord: String?
    /// 手書き認識結果（赤表示用の uncertain インデックス含む）
    @Published var lastRecognitionResult: RecognitionResult?
    @Published var isRecognizing: Bool = false
    @Published var recognitionError: String?
    @Published var perfectStreak: Int = 0

    /// ミニマップ用: 最適落下位置（セマンティック座標 [-1,1]）
    @Published var targetPosition: CGPoint = .zero
    /// ミニマップ用: 配置した単語とその時のセマンティック座標（置かれたときの位置）
    @Published var placedWords: [(word: String, position: CGPoint)] = []

    let scene3D: GameScene3D
    private let manager: SemanticEmbeddingManager
    let demoWords: [String] = [
        "dog", "cat", "lion",
        "tree", "river", "forest",
        "car", "robot", "computer",
        "stone", "chair", "phone",
        "happy", "sad", "freedom"
    ]
    private var demoIndex: Int = 0

    /// 次にドロップされるデモ単語（UI のプレビュー表示用）。
    var nextDemoWord: String {
        guard !demoWords.isEmpty else { return "" }
        return demoWords[demoIndex % demoWords.count]
    }

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

        scene3D.onTargetPositionUpdated = { [weak self] target in
            Task { @MainActor in
                self?.targetPosition = target
            }
        }
    }

    func dropCurrentWord() {
        if isDemoMode {
            guard !demoWords.isEmpty else { return }
            let word = demoWords[demoIndex % demoWords.count]
            demoIndex += 1
            drop(word: word, diskShape: .perfect)
            return
        }

        switch inputMode {
        case .keyboard:
            let trimmed = wordInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            drop(word: trimmed, diskShape: .perfect)
            wordInput = ""
        case .handwriting:
            // 手書き認識は View から Task { await recognizeAndDrop() } で呼ぶ（Swift 6 並行性）
            break
        }
    }

    /// 手書きを認識してドロップ（Vision + スコア → ディスク形状）
    @MainActor
    func recognizeAndDrop() async {
        guard !handwritingDrawing.bounds.isEmpty else {
            recognitionError = "Draw a word first"
            return
        }

        isRecognizing = true
        recognitionError = nil
        lastRecognitionResult = nil

        let size = CGSize(width: 400, height: 120)
        let image = HandwritingCanvasView.image(from: handwritingDrawing, size: size)

        let result = await HandwritingRecognizer.recognize(from: image)

        isRecognizing = false

        guard let rec = result, !rec.text.isEmpty else {
            recognitionError = "Could not recognize. Try writing more clearly."
            lastRecognitionResult = nil
            return
        }

        lastRecognitionResult = rec

        let score = ScoringEngine.evaluateFromRecognition(
            confidence: rec.confidence,
            uncertainCharacterCount: rec.uncertainCharacterIndices.count
        )
        lastScore = score
        lastScoredWord = rec.text

        drop(word: rec.text, diskShape: DiskShape.from(scoreRank: score.rank))
        handwritingDrawing = PKDrawing()
    }

    func clearHandwriting() {
        handwritingDrawing = PKDrawing()
        recognitionError = nil
        lastRecognitionResult = nil
    }

    private func drop(word: String, diskShape: DiskShape) {
        let lowercased = word.lowercased()

        guard let semanticPos = manager.calculatePosition(for: lowercased) else {
            print("No embedding found for word: \(word)")
            return
        }

        let baseMass = max(0.5, min(3.0, Double(lowercased.count) / 3.0))

        let xStr = String(format: "%.3f", semanticPos.x)
        let yStr = String(format: "%.3f", semanticPos.y)
        let massStr = String(format: "%.2f", baseMass)
        print("[Drop] word=\"\(word)\", semantic=(x=\(xStr), y=\(yStr)), mass=\(massStr), shape=\(diskShape)")

        let diskColor = SemanticColorHelper.color(for: semanticPos.x, semanticY: semanticPos.y)
        scene3D.addDisc(
            atSemanticPosition: semanticPos,
            color: diskColor,
            mass: baseMass,
            word: lowercased,
            diskShape: diskShape
        )
        placedWords.append((word: lowercased, position: semanticPos))
        updateStreak(diskShape: diskShape)

        SoundEngine.shared.playDrop()
    }

    private func updateStreak(diskShape: DiskShape) {
        if diskShape == .perfect {
            perfectStreak += 1
        } else {
            perfectStreak = 0
        }
    }
}
