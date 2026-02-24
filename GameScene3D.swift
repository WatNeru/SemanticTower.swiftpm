import SceneKit
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// タワーの土台を3Dで表現するシーン。
/// 後でセマンティック重心に応じて傾きを変える。
final class GameScene3D {
    let scene: SCNScene
    let cameraNode: SCNNode
    private let boardNode: SCNNode

    init() {
        scene = SCNScene()

        // カメラ
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 4, 8)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)
        scene.rootNode.addChildNode(cameraNode)

        // ライト
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(5, 8, 5)
        scene.rootNode.addChildNode(lightNode)

        // 床
        let floor = SCNFloor()
        floor.reflectivity = 0.1
        let floorNode = SCNNode(geometry: floor)
#if canImport(UIKit)
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
#else
        floorNode.geometry?.firstMaterial?.diffuse.contents = NSColor.darkGray
#endif
        scene.rootNode.addChildNode(floorNode)

        // タワーの土台（傾ける板）
        let boardGeometry = SCNBox(width: 6, height: 0.3, length: 6, chamferRadius: 0.2)
#if canImport(UIKit)
        boardGeometry.firstMaterial?.diffuse.contents = UIColor.white
#else
        boardGeometry.firstMaterial?.diffuse.contents = NSColor.white
#endif
        boardNode = SCNNode(geometry: boardGeometry)
        boardNode.position = SCNVector3(0, 1.0, 0)
        scene.rootNode.addChildNode(boardNode)

        // デモ用に1つだけ円盤（単語ディスクのイメージ）を置く
        let discGeometry = SCNCylinder(radius: 0.4, height: 0.2)
#if canImport(UIKit)
        discGeometry.firstMaterial?.diffuse.contents = UIColor.systemBlue
#else
        discGeometry.firstMaterial?.diffuse.contents = NSColor.systemBlue
#endif
        let discNode = SCNNode(geometry: discGeometry)
        discNode.position = SCNVector3(0, 1.3, 0)
        boardNode.addChildNode(discNode)
    }

    /// セマンティック重心に応じて土台の傾き（Z軸回転）を更新。
    /// centerOfMass.x は [-1, 1] を想定。
    func updateBoardTilt(centerOfMass: CGPoint) {
        let maxAngle: CGFloat = .pi / 6 // 約30度
        let clampedX = max(-1.0, min(1.0, Double(centerOfMass.x)))
        let targetAngle = CGFloat(clampedX) * maxAngle

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.2
        boardNode.eulerAngles.z = Float(targetAngle)
        SCNTransaction.commit()
    }
}

