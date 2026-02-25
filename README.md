# SemanticTower

A word-based physics stacking game where words are positioned on a 3D board by their **semantic meaning**. Built with Swift 6 / SwiftUI / SceneKit for Apple Swift Student Challenge.

## How It Works

1. Words are mapped to 2D semantic coordinates using Apple's `NLEmbedding` (on-device word vectors)
2. Each word becomes a disc dropped onto a tilting 3D board
3. The board tilts based on the center of mass — balance your tower!

## Assets & Resources

**This project uses zero external assets.** Everything is generated programmatically at runtime:

| Resource | Method | File |
|---|---|---|
| **Disc textures** (word labels) | `UIGraphicsImageRenderer` — circular textures with text, rings, and color based on semantic position | `DiscTextureGenerator.swift` |
| **Sound effects** (drop, land, score chimes) | `AVAudioEngine` + `AVAudioPCMBuffer` — sine wave synthesis with FM modulation, envelopes, and chords | `SoundEngine.swift` |
| **3D scene** (board, floor, lighting) | SceneKit primitives with PBR materials | `GameScene3D.swift` |
| **Sky gradient** | `UIGraphicsImageRenderer` + `CGGradient` | `GameScene3D.swift` |
| **Semantic colors** | Computed from word coordinates via cosine interpolation | `SemanticColorHelper.swift` |
| **Glass UI effects** | `.ultraThinMaterial` with iOS 26 Liquid Glass fallback | `GlassUIComponents.swift` |
| **Word embeddings** | Apple `NLEmbedding.wordEmbedding(for: .english)` — on-device, no network | `NLEmbeddingProvider.swift` |
| **Handwriting recognition** | Apple `Vision` framework `VNRecognizeTextRequest` — on-device | `HandwritingRecognizer.swift` |

**No third-party libraries, no downloaded assets, no network access required.**

## Accessibility

- WCAG 2.1 AA compliant contrast ratios (4.5:1+)
- Color-blind safe palette (blue/gold/orange instead of red/green)
- VoiceOver labels on interactive elements
- Haptic feedback via `sensoryFeedback` (iOS 17+) / `UINotificationFeedbackGenerator`

## Requirements

- iOS 16.0+
- Xcode with Swift 6 toolchain
- No network connection needed
