import SwiftUI
import SceneKit

/// SceneKit ベースの3Dゲームビュー。
struct GameView3D: View {
    let scene3D: GameScene3D

    var body: some View {
        SceneView(
            scene: scene3D.scene,
            pointOfView: scene3D.cameraNode,
            options: [.allowsCameraControl]
        )
        .ignoresSafeArea()
    }
}

