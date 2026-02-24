import SwiftUI
import SpriteKit

/// SpriteKit の `GameScene` を埋め込んだメインゲームビュー。
struct GameView: View {
    var scene: SKScene {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

