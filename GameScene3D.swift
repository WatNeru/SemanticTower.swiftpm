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

        addAnchorLabels()
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

    /// セマンティック座標をボード上の位置にマッピングしてディスクを追加。
    /// position は [-1, 1] の範囲を想定。
    func addDisc(atSemanticPosition position: CGPoint, color: UIColor) {
        let radius: CGFloat = 0.3
        let height: CGFloat = 0.2

        let geometry = SCNCylinder(radius: radius, height: height)
        geometry.firstMaterial?.diffuse.contents = color

        let node = SCNNode(geometry: geometry)

        // ボードは width=6, length=6。端から少し内側に収まるよう 2.5 を掛ける。
        let localX = Float(position.x) * 2.5
        let localZ = Float(position.y) * 2.5

        node.position = SCNVector3(localX, Float(0.3 / 2 + height / 2), localZ)
        boardNode.addChildNode(node)
    }

    private func addAnchorLabels() {
        let font = UIFont.systemFont(ofSize: 0.4, weight: .semibold)

        func makeTextNode(_ text: String) -> SCNNode {
            let textGeometry = SCNText(string: text, extrusionDepth: 0.02)
            textGeometry.font = font
            textGeometry.firstMaterial?.diffuse.contents = UIColor.systemYellow
            let node = SCNNode(geometry: textGeometry)
            let (minVec, maxVec) = textGeometry.boundingBox
            let width = maxVec.x - minVec.x
            node.pivot = SCNMatrix4MakeTranslation((minVec.x + width / 2), minVec.y, 0)
            node.scale = SCNVector3(0.3, 0.3, 0.3)
            return node
        }

        // X軸: Nature (+X), Machine (-X)
        let natureNode = makeTextNode("Nature")
        natureNode.position = SCNVector3(3.2, 1.6, 0)
        natureNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(natureNode)

        let machineNode = makeTextNode("Machine")
        machineNode.position = SCNVector3(-3.2, 1.6, 0)
        machineNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(machineNode)

        // Y軸（セマンティックでは垂直）を Z 方向に対応させる: Living (+Z), Object (-Z)
        let livingNode = makeTextNode("Living")
        livingNode.position = SCNVector3(0, 1.6, 3.2)
        livingNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(livingNode)

        let objectNode = makeTextNode("Object")
        objectNode.position = SCNVector3(0, 1.6, -3.2)
        objectNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(objectNode)
    }
}

