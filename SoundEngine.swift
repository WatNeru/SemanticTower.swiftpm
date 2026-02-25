import AVFoundation
import Foundation

/// 外部オーディオファイル不要のプロシージュラル音声エンジン。
/// AVAudioEngine + 正弦波合成で全サウンドをリアルタイム生成。
/// SSC の 25MB 制限を圧迫しない。
@MainActor
final class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private var isSetUp = false

    private init() {
        setUp()
    }

    private func setUp() {
        guard !isSetUp else { return }
        engine.attach(playerNode)
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.4
        do {
            try engine.start()
            playerNode.play()
            isSetUp = true
        } catch {
            print("[SoundEngine] Failed to start: \(error)")
        }
    }

    // MARK: - Game Sound Effects

    /// 単語がドロップされたとき（下降音）
    func playDrop() {
        playTone(
            baseFreq: 880,
            endFreq: 330,
            duration: 0.25,
            envelope: .descending
        )
    }

    /// ディスクがボードに着地したとき（短いインパクト音）
    func playLand() {
        playTone(
            baseFreq: 220,
            endFreq: 180,
            duration: 0.08,
            envelope: .impact
        )
    }

    /// Perfect スコア（上昇する和音チャイム）
    func playPerfect() {
        playChime(frequencies: [523, 659, 784], duration: 0.4)
    }

    /// Nice スコア（2音の短いチャイム）
    func playNice() {
        playChime(frequencies: [440, 554], duration: 0.3)
    }

    /// Miss スコア（低い短いブザー音）
    func playMiss() {
        playTone(
            baseFreq: 150,
            endFreq: 120,
            duration: 0.2,
            envelope: .descending
        )
    }

    /// ボタンタップなどの軽い音
    func playTap() {
        playTone(
            baseFreq: 1200,
            endFreq: 1000,
            duration: 0.04,
            envelope: .impact
        )
    }

    // MARK: - Synthesis

    private enum Envelope {
        case descending
        case impact
        case sustained
    }

    private func playTone(
        baseFreq: Double,
        endFreq: Double,
        duration: Double,
        envelope: Envelope
    ) {
        guard isSetUp else { return }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: playerNode.outputFormat(forBus: 0),
            frameCapacity: frameCount
        ) else { return }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return }
        let totalFrames = Double(frameCount)

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / totalFrames
            let freq = baseFreq + (endFreq - baseFreq) * progress
            let phase = 2.0 * .pi * freq * Double(frame) / sampleRate

            var amplitude: Double
            switch envelope {
            case .descending:
                amplitude = 1.0 - progress
            case .impact:
                amplitude = max(0, 1.0 - progress * 4.0)
            case .sustained:
                let attack = min(progress * 10, 1.0)
                let release = max(0, 1.0 - (progress - 0.7) * 3.33)
                amplitude = min(attack, release)
            }

            channelData[frame] = Float(sin(phase) * amplitude * 0.3)
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }

    private func playChime(frequencies: [Double], duration: Double) {
        guard isSetUp else { return }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: playerNode.outputFormat(forBus: 0),
            frameCapacity: frameCount
        ) else { return }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return }
        let totalFrames = Double(frameCount)

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / totalFrames
            var sample: Double = 0

            for (index, freq) in frequencies.enumerated() {
                let delay = Double(index) * 0.08
                let localProgress = max(0, progress - delay) / (1.0 - delay)
                guard localProgress > 0 else { continue }

                let phase = 2.0 * .pi * freq * Double(frame) / sampleRate
                let envAttack = min(localProgress * 15, 1.0)
                let envDecay = max(0, 1.0 - localProgress * 1.5)
                let amp = min(envAttack, envDecay) / Double(frequencies.count)
                sample += sin(phase) * amp
            }

            channelData[frame] = Float(sample * 0.3)
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }
}
