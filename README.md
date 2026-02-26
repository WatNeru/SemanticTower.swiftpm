# SemanticTower

A word-based physics stacking game where words are positioned on a 3D board by their **semantic meaning**.  
Built with Swift 6 / SwiftUI / SceneKit for the **Apple Swift Student Challenge**.

## Overview

SemanticTower turns language into a physical puzzle.  
Words that are semantically similar land near each other on the board; distant concepts land far apart.  
Your goal is to drop words in a way that keeps the tower balanced for as long as possible.

## Gameplay

1. Type or handwrite a word (e.g. “sun”, “ocean”, “robot”).
2. The game fetches that word’s 2D semantic coordinate from Apple’s on-device `NLEmbedding`.
3. A disc is spawned at the corresponding position on a 3D board and dropped with physics.
4. The board tilts based on the center of mass of all discs.
5. If the tilt exceeds a safe threshold, discs start sliding and falling — try to keep the tower stable.

Additional UI:

- Live **balance indicator** showing the tower’s center of mass.
- **Game stats view** with placed / fallen counts and score.
- **Onboarding** explaining the concept of semantic space and basic controls.

## How It Works (Technology)

- **Semantic space**
  - Uses `NLEmbedding.wordEmbedding(for: .english)` to project words into a 2D semantic plane.
  - Custom scaling & rotation keep the board readable and visually balanced.

- **Physics & 3D scene**
  - SceneKit-based board, floor, and PBR materials (`GameScene3D.swift`).
  - Discs are dynamic rigid bodies; the board reacts to mass distribution.
  - A semantic “sky gradient” is rendered with `UIGraphicsImageRenderer` + `CGGradient`.

- **Input**
  - Standard keyboard input through SwiftUI.
  - Handwriting input powered by `Vision` (`VNRecognizeTextRequest`) for a playful, sketch-like feel.

- **Scoring**
  - Internal scoring engine rewards:
    - Discovering new regions of semantic space.
    - Building stable clusters of related words.
    - Recovering from near-falls by counter-balancing the tower.

## Assets & Resources

**This project uses zero external assets.** Everything is generated programmatically at runtime:

| Resource | Method | File |
|---|---|---|
| **Disc textures** (word labels + icons) | `UIGraphicsImageRenderer` — circular textures with SF Symbol / Emoji icon, word text, rings, and color based on semantic position | `DiscTextureGenerator.swift`, `WordIconMapper.swift` |
| **Word icons** (140+ mappings) | SF Symbols (Apple built-in, `UIImage(systemName:)`) for most words; System Emoji rendered as `NSAttributedString` for words without SF Symbol coverage (e.g. 🦁🐋🤖🪨) | `WordIconMapper.swift` |
| **Sound effects** (drop, land, score chimes) | `AVAudioEngine` + `AVAudioPCMBuffer` — sine wave synthesis with FM modulation, envelopes, and chords | `SoundEngine.swift` |
| **3D scene** (board, floor, lighting) | SceneKit primitives with PBR materials | `GameScene3D.swift` |
| **Sky gradient** | `UIGraphicsImageRenderer` + `CGGradient` | `GameScene3D.swift` |
| **Semantic colors** | Computed from word coordinates via cosine interpolation | `SemanticColorHelper.swift` |
| **Glass UI effects** | `.ultraThinMaterial` with iOS “Liquid Glass”-style fallback | `GlassUIComponents.swift` |
| **Word embeddings** | Apple `NLEmbedding.wordEmbedding(for: .english)` — on-device, no network | `NLEmbeddingProvider.swift` |
| **Handwriting recognition** | Apple `Vision` framework `VNRecognizeTextRequest` — on-device | `HandwritingRecognizer.swift` |

**No third-party libraries, no downloaded assets, and no network access are required.**

## Accessibility

- **Contrast**: A color palette chosen to meet WCAG 2.1 AA contrast ratios (4.5:1+).
- **Color-blind support**: Uses blue / gold / orange instead of red / green for critical state.
- **VoiceOver**: Descriptive labels for primary interactive elements and score changes.
- **Haptics**: Uses `sensoryFeedback` (iOS 17+) or `UINotificationFeedbackGenerator` to reinforce key events (drops, landings, score milestones).

## Privacy

- No network requests are made at any time.
- All processing (embeddings, Vision handwriting recognition, sound synthesis) happens **on device**.
- No analytics, tracking, or data collection.

## Building & Running

Requirements:

- iOS 16.0 or later.
- Xcode with the Swift 6 toolchain, or Swift Playgrounds on iPad.

To run:

1. Open `SemanticTower.swiftpm` in Xcode or Swift Playgrounds.
2. Select an iOS device or simulator running iOS 16.0+.
3. Build & run. The main entry point is `MyApp.swift` (`@main`), which presents `ContentView`.

## Review Guide (Swift Student Challenge)

This section is written for reviewers of the **Apple Swift Student Challenge** and summarizes how to explore the project.

### What to Try First

1. **Basic play**
   - Enter simple words like `sun`, `moon`, `river`, `robot`, `music`.
   - Watch how semantically related words cluster on the board.

2. **Explore semantic space**
   - Try opposites or distant concepts: `fire` vs `water`, `cat` vs `spaceship`, `love` vs `gravity`.
   - Observe how the tower tilts as you build clusters far from the center.

3. **Handwriting input**
   - Use the handwriting canvas to write a word.
   - Check how `Vision` recognition feeds into the same semantic pipeline as typed input.

4. **Recovering balance**
   - Intentionally unbalance the tower, then use counter-words on the opposite side to stabilize it.

### Code Map (Where Things Live)

The package target is configured with `path: "."`, so Swift files live at the project root.
Key files for reviewers:

- **App / UI**
  - `MyApp.swift`: App entry point.
  - `ContentView.swift`: Top-level SwiftUI view, routes between onboarding, game, and settings.
  - `GameView.swift`, `GameView3D.swift`: SwiftUI wrappers for the SceneKit game scene.
  - `OnboardingView.swift`: Explains the concept and controls.
  - `SettingsView.swift`: Game / accessibility options.
  - `GameStatsView.swift`, `ScoreFeedbackView.swift`, `BalanceIndicator.swift`: HUD and feedback UI.
  - `AnimatedBackground.swift`, `GlassUIComponents.swift`, `Theme.swift`, `SemanticColorHelper.swift`: Visual styling and glass / gradient effects.

- **Game logic & 3D scene**
  - `GameScene3D.swift`: SceneKit-based board, discs, physics, and lighting.
  - `GameScene.swift`: Higher-level orchestration around the SceneKit scene.
  - `SemanticGameController.swift`: Connects UI input, semantic engine, physics, and scoring.
  - `GameSettings.swift`: Centralized tuning parameters for difficulty, thresholds, etc.

- **Semantic engine & data**
  - `NLEmbeddingProvider.swift`: Access to Apple’s on-device `NLEmbedding`.
  - `SemanticEmbeddingTypes.swift`, `SemanticEmbeddingManager.swift`: Types and logic for mapping words into 2D coordinates.
  - `WordDatabase.swift`: Curated word list and metadata used for suggestions and internal tests.
  - `WordIconMapper.swift`: Maps words to SF Symbols or Emoji icons.

- **Rendering & feedback**
  - `DiscShapeType.swift`, `DiscMaterialHelper.swift`, `DiscTextureGenerator.swift`: Disc visuals, materials, and textures.
  - `SoundEngine.swift`: Procedural sound synthesis for drops, landings, and score events.
  - `FallNotificationView.swift`: Visual cue when discs fall off the board.

- **Input & handwriting**
  - `WordInputBar.swift`: Input bar UI and validation.
  - `HandwritingCanvasView.swift`: Drawing surface for handwriting input.
  - `HandwritingRecognizer.swift`: `Vision`-based text recognition that feeds recognized words into the same pipeline.

- **Core logic & tests**
  - `ScoringEngine.swift`: Pure Swift scoring logic, independent of Apple-only frameworks.
  - `SemanticEngineDebugTests.swift`, `TestEmbeddingProvider.swift`: Lightweight debug tests (run via `SemanticEngineDebugTests.runAll()` in `#if DEBUG`).

