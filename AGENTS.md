# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

SemanticTower is a **native iOS game** (Swift 6 / SwiftUI / SceneKit) where players drop words onto a 3D board positioned by their semantic meaning. It targets **iOS 16.0+** and uses `AppleProductTypes` in `Package.swift` (Swift Playgrounds-style packaging).

### Linux Cloud VM limitations

- **Full build (`swift build`) will fail** on Linux because `Package.swift` imports `AppleProductTypes`, which only exists in Xcode/Swift Playgrounds.
- **Apple-only frameworks** (`SceneKit`, `SpriteKit`, `UIKit`, `SwiftUI`, `NaturalLanguage`) are not available on Linux. The app cannot be run on this VM.
- Building and running the full app **requires macOS with Xcode**.

### What CAN be done on the Linux VM

1. **Lint**: `swiftlint lint` (SwiftLint is installed at `/usr/local/bin/swiftlint`).
2. **Compile & test platform-independent logic**: The semantic engine, scoring engine, and debug tests can be compiled and run using `swiftc` directly:
   ```sh
   cd /workspace && swiftc -D DEBUG -o /tmp/test_runner \
     -L /opt/swift/usr/lib/swift/linux -I /opt/swift/usr/lib/swift/linux -lCoreGraphics \
     SemanticEmbeddingTypes.swift SemanticEmbeddingManager.swift ScoringEngine.swift \
     TestEmbeddingProvider.swift SemanticEngineDebugTests.swift <your_test_main.swift>
   LD_LIBRARY_PATH=/opt/swift/usr/lib/swift/linux /tmp/test_runner
   ```
   A custom `CoreGraphics` shim module is installed at `/opt/swift/usr/lib/swift/linux/` providing `CGVector` (since `CGPoint`/`CGFloat` come from Foundation on Linux but `CGVector` does not).
3. **Syntax check all files**: `swiftc -parse *.swift` works for syntax-level validation.

### Key architecture notes

- Files with **no Apple-framework dependency** (compilable on Linux): `ScoringEngine.swift`, `SemanticEmbeddingTypes.swift`, `SemanticEmbeddingManager.swift`, `TestEmbeddingProvider.swift`, `SemanticEngineDebugTests.swift`.
- Files **requiring Apple frameworks**: `MyApp.swift`, `ContentView.swift`, `GameScene3D.swift`, `GameScene.swift`, `GameView3D.swift`, `GameView.swift`, `NLEmbeddingProvider.swift`, `SemanticGameController.swift`.
- Tests are informal (`SemanticEngineDebugTests.runAll()` with `assert` statements in `#if DEBUG`), not XCTest.
- Swift 6.0.3 is installed at `/opt/swift/usr/bin/swift`.
