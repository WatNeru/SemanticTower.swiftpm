import Foundation
import SwiftUI

/// 入力モード
enum InputMode: String, CaseIterable {
    case keyboard = "Keyboard"
    case handwriting = "Handwriting"
}

/// セマンティック・エンジンと 3D シーンをつなぐ ViewModel。
@MainActor
final class SemanticGameController: ObservableObject {
    @Published var wordInput: String = ""
    @Published var isDemoMode: Bool = true
    @Published var inputMode: InputMode = .handwriting
    @Published var lastScore: ScoreResult?
    @Published var lastScoredWord: String?
    @Published var lastRecognitionResult: RecognitionResult?
    @Published var isRecognizing: Bool = false
    @Published var recognitionError: String?
    @Published var perfectStreak: Int = 0

    // 手書きキャンバス用（UIImage ベース、PencilKit 不要）
    @Published var handwritingImage: UIImage?
    @Published var hasHandwritingStrokes: Bool = false
    @Published var clearCanvasSignal: Bool = false

    @Published var targetPosition: CGPoint = .zero
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
            break
        }
    }

    @MainActor
    func recognizeAndDrop() async {
        guard let image = handwritingImage else {
            recognitionError = "Draw a word first"
            return
        }

        isRecognizing = true
        recognitionError = nil
        lastRecognitionResult = nil

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
        clearHandwriting()
    }

    func clearHandwriting() {
        clearCanvasSignal = true
        handwritingImage = nil
        hasHandwritingStrokes = false
        recognitionError = nil
        lastRecognitionResult = nil
        DispatchQueue.main.async { [weak self] in
            self?.clearCanvasSignal = false
        }
    }

    private func drop(word: String, diskShape: DiskShape) {
        let lowercased = word.lowercased()

        guard let semanticPos = manager.calculatePosition(for: lowercased) else {
            print("No embedding found for word: \(word)")
            return
        }

        let baseMass = max(0.5, min(3.0, Double(lowercased.count) / 3.0))

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
