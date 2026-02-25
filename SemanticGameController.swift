import Foundation
import SwiftUI

enum InputMode: String, CaseIterable {
    case keyboard = "Keyboard"
    case handwriting = "Handwriting"
}

@MainActor
final class SemanticGameController: ObservableObject {
    @Published var wordInput: String = ""
    @Published var isDemoMode: Bool = false
    @Published var inputMode: InputMode = .handwriting

    // 共通フィードバック（どちらのモードでも最新の結果を表示）
    @Published var lastScore: ScoreResult?
    @Published var lastScoredWord: String?
    @Published var perfectStreak: Int = 0
    @Published var lastFallenWord: String?
    @Published var fallCount: Int = 0

    // 手書き用
    @Published var handwritingImage: UIImage?
    @Published var hasHandwritingStrokes: Bool = false
    @Published var clearCanvasSignal: Bool = false
    @Published var lastRecognitionResult: RecognitionResult?
    @Published var isRecognizing: Bool = false
    @Published var recognitionError: String?

    // キーボード用
    @Published var keyboardError: String?

    @Published var targetPosition: CGPoint = .zero
    @Published var placedWords: [(word: String, position: CGPoint)] = []

    let scene3D: GameScene3D
    let settings: GameSettings
    private var manager: SemanticEmbeddingManager
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

    init(settings: GameSettings = GameSettings()) {
        self.settings = settings
        scene3D = GameScene3D()

        let provider = NLEmbeddingProvider()
        manager = SemanticEmbeddingManager(
            provider: provider,
            config: SemanticConfig(
                defaultAnchors: settings.currentAnchors,
                candidateWords: [],
                positionScale: 4.0
            )
        )

        scene3D.onTargetPositionUpdated = { [weak self] target in
            Task { @MainActor in self?.targetPosition = target }
        }
        scene3D.onDiscFell = { [weak self] word in
            Task { @MainActor in self?.handleDiscFell(word: word) }
        }

        scene3D.updateAnchorLabels(settings: settings)
    }

    /// 設定変更時にエンジンとラベルを再構築
    func applySettings() {
        let provider = NLEmbeddingProvider()
        manager = SemanticEmbeddingManager(
            provider: provider,
            config: SemanticConfig(
                defaultAnchors: settings.currentAnchors,
                candidateWords: [],
                positionScale: 4.0
            )
        )
        scene3D.updateAnchorLabels(settings: settings)
    }

    // MARK: - Demo mode drop

    func dropDemoWord() {
        guard !demoWords.isEmpty else { return }
        let word = demoWords[demoIndex % demoWords.count]
        demoIndex += 1
        clearFeedback()
        drop(word: word, diskShape: .perfect)
        lastScore = ScoreResult(rank: .perfect, accuracy: 1.0)
        lastScoredWord = word
        SoundEngine.shared.playPerfect()
    }

    // MARK: - Keyboard drop (independent)

    func dropKeyboardWord() {
        let trimmed = wordInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }

        clearFeedback()
        keyboardError = nil

        let hasEmbedding = manager.calculatePosition(for: trimmed) != nil

        if hasEmbedding {
            drop(word: trimmed, diskShape: .perfect)
            lastScore = ScoreResult(rank: .perfect, accuracy: 1.0)
            lastScoredWord = trimmed
            SoundEngine.shared.playPerfect()
        } else {
            lastScore = ScoreResult(rank: .miss, accuracy: 0)
            lastScoredWord = trimmed
            keyboardError = "Unknown word: \"\(trimmed)\""
            SoundEngine.shared.playMiss()
        }
        wordInput = ""
    }

    // MARK: - Handwriting drop (independent)

    @MainActor
    func recognizeAndDrop() async {
        guard let image = handwritingImage else {
            recognitionError = "Draw a word first"
            return
        }

        clearFeedback()
        isRecognizing = true
        recognitionError = nil
        lastRecognitionResult = nil

        let result = await HandwritingRecognizer.recognize(from: image)
        isRecognizing = false

        guard let rec = result, !rec.text.isEmpty else {
            recognitionError = "Could not recognize. Try again."
            lastRecognitionResult = nil
            SoundEngine.shared.playMiss()
            return
        }

        lastRecognitionResult = rec

        let score = ScoringEngine.evaluateFromRecognition(
            confidence: rec.confidence,
            uncertainCharacterCount: rec.uncertainCharacterIndices.count
        )
        lastScore = score
        lastScoredWord = rec.text

        let shape = DiskShape.from(scoreRank: score.rank)
        drop(word: rec.text, diskShape: shape)

        switch score.rank {
        case .perfect: SoundEngine.shared.playPerfect()
        case .nice: SoundEngine.shared.playNice()
        case .miss: SoundEngine.shared.playMiss()
        }

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

    // MARK: - Private

    private func clearFeedback() {
        lastScore = nil
        lastScoredWord = nil
        keyboardError = nil
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

    func resetGame() {
        scene3D.resetBoard()
        placedWords.removeAll()
        perfectStreak = 0
        fallCount = 0
        lastFallenWord = nil
        lastScore = nil
        lastScoredWord = nil
        clearHandwriting()
        wordInput = ""
        SoundEngine.shared.playTap()
    }

    private func handleDiscFell(word: String) {
        placedWords.removeAll { $0.word == word }
        lastFallenWord = word
        fallCount += 1
        perfectStreak = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.lastFallenWord == word {
                self?.lastFallenWord = nil
            }
        }
    }
}
