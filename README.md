# SemanticTower

**A word-based physics stacking game where words are positioned on a 3D board by their semantic meaning.**

Built entirely with Apple frameworks — Swift 6, SwiftUI, SceneKit, NaturalLanguage, Vision, AVFoundation. Zero external assets. Zero network access. Designed for the Apple Swift Student Challenge.

---

## How to Play

1. **Type or draw** a word (keyboard or finger drawing)
2. The word is mapped to a **2D semantic coordinate** using Apple's on-device `NLEmbedding` word vectors
3. A 3D disc in a **category-specific shape** (star, heart, hexagon, gear...) is dropped onto the tilting board
4. The board **tilts based on the semantic center of mass** — similar words cluster, opposites spread
5. **Keep the tower balanced!** If it tilts too far, discs fall off

## Features

| Feature | Description |
|---|---|
| **Semantic Positioning** | Words placed by AI word-embedding similarity to 4 customizable anchor concepts |
| **9 Disc Shapes** | Star, heart, hexagon, diamond, flower, gear, cloud, rounded, circle — mapped by word category |
| **1500+ Word Database** | Icons (SF Symbols + Emoji) and shapes for animals, nature, machines, food, emotions, verbs, and more |
| **Handwriting Input** | Finger drawing with Vision on-device text recognition and per-character confidence feedback |
| **Procedural Audio** | All sounds synthesized at runtime via AVAudioEngine (drop, land, score chimes, fall) |
| **Spring Physics** | Board tilt uses spring interpolation with dead zone for natural, gradual movement |
| **Semantic Map** | Minimap + expandable full map showing placed words and optimal drop target |
| **8 Anchor Presets** | Default, Emotion, Science, Society, Elements, Time, Space, Art |
| **Accessibility** | WCAG 2.1 AA colors, high-contrast mode, large text, haptic feedback, VoiceOver labels |
| **Onboarding** | 3-step tutorial explaining the semantic positioning concept |

## Architecture (MVVM)

```
SemanticTower.swiftpm/
│
├── MyApp.swift                         App entry point + onboarding flow
│
├── Models/                             Data layer
│   ├── SemanticEmbeddingTypes.swift      Protocol, AnchorSet, SemanticConfig
│   ├── GameSettings.swift                Persistent settings (@AppStorage)
│   ├── ScoringEngine.swift               Word accuracy evaluation
│   └── WordDatabase.swift                1500+ word → icon + shape mappings
│
├── ViewModels/                         Business logic
│   └── SemanticGameController.swift      Connects UI ↔ engine ↔ 3D scene
│
├── Views/                              Presentation layer
│   ├── Game/
│   │   ├── ContentView.swift              Main game screen + HUD composition
│   │   ├── GameView3D.swift               SceneKit view wrapper
│   │   └── GameView.swift                 SpriteKit view wrapper (legacy)
│   ├── HUD/
│   │   ├── BalanceIndicator.swift         Center-of-mass radar
│   │   ├── CompassOverlayView.swift       Semantic minimap + expanded map
│   │   ├── GameStatsView.swift            Height / discs / streak / balance
│   │   ├── ScoreFeedbackView.swift        Animated score popup
│   │   ├── FallNotificationView.swift     Disc fall notification
│   │   └── WordInputBar.swift             Keyboard input bar
│   ├── Input/
│   │   └── HandwritingCanvasView.swift    Finger drawing canvas + panel
│   ├── Onboarding/
│   │   └── OnboardingView.swift           3-step tutorial
│   └── Settings/
│       └── SettingsView.swift             Anchor / sound / accessibility
│
├── Engine/                             Core logic (framework-independent)
│   ├── SemanticEmbeddingManager.swift    Semantic coordinate calculation
│   ├── NLEmbeddingProvider.swift         NLEmbedding wrapper
│   ├── HandwritingRecognizer.swift       Vision text recognition
│   └── SoundEngine.swift                 Procedural audio synthesis
│
├── Scene/                              SceneKit 3D layer
│   ├── GameScene3D.swift                 Board, discs, physics, tilt
│   ├── GameScene.swift                   SpriteKit scene (legacy)
│   ├── DiscShapeType.swift               9 UIBezierPath shape generators
│   ├── DiscTextureGenerator.swift        Programmatic disc face textures
│   ├── DiscMaterialHelper.swift          PBR materials for discs
│   ├── SemanticColorHelper.swift         Anchor-weighted color mixing
│   └── WordIconMapper.swift              Icon rendering delegate
│
├── Theme/                              Design system
│   ├── Theme.swift                       Colors, gradients, glass, glow
│   ├── AnimatedBackground.swift          Starfield + nebula Canvas
│   └── GlassUIComponents.swift           Glass effect modifiers
│
├── Utilities/
│   └── HapticFeedback.swift              Haptic feedback helper
│
├── Tests/
│   ├── TestEmbeddingProvider.swift        Mock embedding provider
│   └── SemanticEngineDebugTests.swift     Debug assertions
│
└── Assets.xcassets/                    App icon
```

## Zero External Assets

Everything is generated programmatically at runtime:

| Resource | Method | Source |
|---|---|---|
| Disc textures | `UIGraphicsImageRenderer` | `DiscTextureGenerator.swift` |
| Word icons | SF Symbols + System Emoji | `WordDatabase.swift` |
| Disc shapes | `UIBezierPath` → `SCNShape` | `DiscShapeType.swift` |
| Sound effects | `AVAudioEngine` sine wave synthesis | `SoundEngine.swift` |
| 3D scene | SceneKit primitives + PBR materials | `GameScene3D.swift` |
| Sky gradient | `CGGradient` | `GameScene3D.swift` |
| Semantic colors | Anchor-weighted RGB mixing | `SemanticColorHelper.swift` |
| Word embeddings | `NLEmbedding.wordEmbedding(for: .english)` | On-device |
| Text recognition | `VNRecognizeTextRequest` | On-device |
| App icon | Python/Pillow (build-time only) | `AppIcon.png` |

**No third-party libraries. No downloaded assets. No network access.**

## Accessibility

- **Color-blind safe**: Blue/gold/orange palette (not red/green)
- **WCAG 2.1 AA**: 4.5:1+ contrast ratios, dynamically calculated per disc color
- **High Contrast mode**: Increases HUD text opacity for readability
- **Larger Text mode**: Scales all HUD elements proportionally
- **Multi-channel info**: Shape + color + icon + text — no info relies on color alone
- **Haptic feedback**: `sensoryFeedback` (iOS 17+) / `UINotificationFeedbackGenerator`
- **VoiceOver**: Accessibility labels on interactive elements

## Technologies Used

| Framework | Purpose |
|---|---|
| **SceneKit** | 3D rendering, physics simulation, PBR materials |
| **NaturalLanguage** | On-device word embeddings (NLEmbedding) |
| **Vision** | On-device handwriting recognition |
| **AVFoundation** | Procedural audio synthesis |
| **SwiftUI** | UI framework |
| **Core Graphics** | Texture generation, shape paths |
| **UIKit** | Finger drawing canvas, haptic feedback |

## Requirements

- iOS 16.0+
- Xcode with Swift 6 toolchain
- No network connection needed
- Runs on iPhone and iPad
