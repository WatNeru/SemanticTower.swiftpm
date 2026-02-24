import SceneKit
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// タワーの土台を3Dで表現するシーン。
/// 後でセマンティック重心に応じて傾きを変える。
final class GameScene3D: NSObject, SCNPhysicsContactDelegate {
    let scene: SCNScene
    let cameraNode: SCNNode
    private var boardNode: SCNNode
    private var currentAngle: CGFloat = 0
    private struct SemanticDisc {
        let node: SCNNode
        let semanticX: Double
        var isOnBoard: Bool
    }
    private var discs: [SemanticDisc] = []

    private enum PhysicsCategory {
        static let floor: Int = 1 << 0
        static let board: Int = 1 << 1
        static let disc: Int = 1 << 2
    }

    override init() {
        // すべての `let` プロパティを super.init() の前に初期化する。
        scene = SCNScene()
        cameraNode = SCNNode()
        boardNode = SCNNode()
        super.init()

        // 物理世界の基本設定（重力はデフォルトのまま下向き）。
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scene.physicsWorld.contactDelegate = self

        // カメラ
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
        // 床は静的な物理ボディとして扱う。
        let floorBody = SCNPhysicsBody.static()
        floorBody.restitution = 0.05
        floorBody.friction = 1.0
        floorBody.categoryBitMask = PhysicsCategory.floor
        floorBody.contactTestBitMask = PhysicsCategory.disc
        floorNode.physicsBody = floorBody
        scene.rootNode.addChildNode(floorNode)

        // タワーの土台（傾ける板）
        let boardGeometry = SCNBox(width: 6, height: 0.4, length: 6, chamferRadius: 0.2)
#if canImport(UIKit)
        boardGeometry.firstMaterial?.diffuse.contents = UIColor.white
#else
        boardGeometry.firstMaterial?.diffuse.contents = NSColor.white
#endif
        boardNode = SCNNode(geometry: boardGeometry)
        boardNode.position = SCNVector3(0, 1.0, 0)
        // 土台は「手で動かす」オブジェクトなので、運動学的ボディにする。
        let boardBody = SCNPhysicsBody.kinematic()
        boardBody.restitution = 0.05
        boardBody.friction = 0.9
        boardBody.categoryBitMask = PhysicsCategory.board
        boardBody.contactTestBitMask = PhysicsCategory.disc
        boardNode.physicsBody = boardBody
        scene.rootNode.addChildNode(boardNode)

        addAnchorLabels()
    }

    /// セマンティック座標をボード上の位置にマッピングしてディスクを追加。
    /// position は [-1, 1] の範囲を想定。
    func addDisc(atSemanticPosition position: CGPoint, color: UIColor, mass: Double) {
        let radius: CGFloat = 0.3
        let height: CGFloat = 0.2

        let geometry = SCNCylinder(radius: radius, height: height)
        geometry.firstMaterial?.diffuse.contents = color

        let node = SCNNode(geometry: geometry)

        // ボードは width=6, length=6。端から少し内側に収まるよう 2.5 を掛ける。
        let localX = Float(position.x) * 2.5
        let localZ = Float(position.y) * 2.5

        // 上の方から自由落下させるため、Y を高めに設定。
        let startY: Float = 4.0
        node.position = SCNVector3(localX, startY, localZ)

        // 動的な物理ボディ：重いけれどあまり弾まない設定。
        let body = SCNPhysicsBody.dynamic()
        body.mass = CGFloat(mass)
        body.restitution = 0.05   // 反発をかなり低めに
        body.friction = 0.9       // すべりにくく
        body.angularDamping = 0.3
        body.damping = 0.2
        // すり抜け防止のため、ある程度の速さ以上で連続衝突判定を有効にする。
        body.continuousCollisionDetectionThreshold = 0.01
        body.categoryBitMask = PhysicsCategory.disc
        body.contactTestBitMask = PhysicsCategory.board | PhysicsCategory.floor
        node.physicsBody = body

        scene.rootNode.addChildNode(node)

        // 傾き計算用には、意味座標の差が画面上でもはっきり出るようにスケーリングする。
        // 例: NLEmbedding の差分は [-0.2, 0.2] 程度に収まるので、4倍して [-0.8, 0.8] まで広げる。
        let scaleForTilt: CGFloat = 4.0
        let scaledX = max(-1.0, min(1.0, position.x * scaleForTilt))

        // まだ空中にあるので、ボードには乗っていない扱い（isOnBoard = false）
        discs.append(
            SemanticDisc(
                node: node,
                semanticX: Double(scaledX),
                isOnBoard: false
            )
        )
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

    /// 現在積まれているディスクのセマンティック重心から、ターゲットの傾きを決める。
    private func updateTiltFromDiscs() {
        let activeDiscs = discs.filter { $0.isOnBoard }
        guard !activeDiscs.isEmpty else {
            // 盤上にディスクがない場合は水平にリセット。
            updateBoardTilt(centerOfMass: .zero)
            return
        }

        // 個数や重みには依存させず、「幾何学的な中心」だけを見る。
        let sumX = activeDiscs.reduce(0.0) { partial, disc in
            partial + disc.semanticX
        }
        let centerX = sumX / Double(activeDiscs.count)
        let center = CGPoint(x: centerX, y: 0)

        // デバッグ用ログ: ディスク配置と重心を出力。
        let positionsSummary = activeDiscs
            .map { String(format: "%.2f", $0.semanticX) }
            .joined(separator: ", ")
        let centerStr = String(format: "%.3f", centerX)
        print("[Tilt] activeDiscs=\(activeDiscs.count), xPositions=[\(positionsSummary)], centerX=\(centerStr)")

        updateBoardTilt(centerOfMass: center)
    }

    /// セマンティック重心に応じて土台の傾き（Z軸回転）を更新。
    /// centerOfMass.x は [-1, 1] を想定。
    /// 傾きの角速度は常に等速で、十分に傾くとディスクがすべて落ちる。
    private func updateBoardTilt(centerOfMass: CGPoint) {
        // ゲームとしては大きく傾いてすべて落ちるところまで回転させたいので、
        // 最大角度を約80度に設定する。
        // 画面上で分かりやすく、かつ極端すぎない程度の最大傾き。
        let maxAngle: CGFloat = .pi / 3 // ≈60度
        let clampedX = max(-1.0, min(1.0, Double(centerOfMass.x)))
        let epsilon = 0.05

        let targetAngle: CGFloat
        if abs(clampedX) < epsilon {
            // ほぼバランスしているときは水平に戻す。
            targetAngle = 0
        } else {
            // 右に重心があれば常に +maxAngle、左なら -maxAngle を
            // 一定の角速度で目指す。
            let sign: CGFloat = clampedX >= 0 ? 1 : -1
            targetAngle = sign * maxAngle
        }

        let delta = targetAngle - currentAngle
        guard abs(delta) > 0.001 else { return }

        // ゲームらしく「ゆっくり倒れていく」感覚を出すために 3度/秒程度に抑える。
        let angularSpeed: CGFloat = .pi / 60 // 3度/秒
        let duration = max(0.05, TimeInterval(abs(delta) / angularSpeed))

        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        boardNode.eulerAngles.z = Float(targetAngle)
        SCNTransaction.commit()

        currentAngle = targetAngle
    }

    // MARK: - SCNPhysicsContactDelegate

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let nodeA = contact.nodeA as SCNNode?, let nodeB = contact.nodeB as SCNNode? else { return }

        let categoryA = nodeA.physicsBody?.categoryBitMask ?? 0
        let categoryB = nodeB.physicsBody?.categoryBitMask ?? 0

        // ディスクとボードの接触 → 盤上に乗ったとみなす
        if (categoryA == PhysicsCategory.disc && categoryB == PhysicsCategory.board) ||
            (categoryA == PhysicsCategory.board && categoryB == PhysicsCategory.disc) {
            let discNode = categoryA == PhysicsCategory.disc ? nodeA : nodeB
            // ボードの「天面」付近との接触だけを盤上とみなす（側面との一時的な接触を除外）。
            let boardY = boardNode.presentation.position.y
            let contactY = contact.contactPoint.y
            if contactY < boardY + 0.15 {
                return
            }
            if let index = discs.firstIndex(where: { $0.node === discNode }) {
                discs[index].isOnBoard = true
                updateTiltFromDiscs()
            }
            return
        }

        // ディスクと床の接触 → 完全に落ちたとみなして削除
        if (categoryA == PhysicsCategory.disc && categoryB == PhysicsCategory.floor) ||
            (categoryA == PhysicsCategory.floor && categoryB == PhysicsCategory.disc) {
            let discNode = categoryA == PhysicsCategory.disc ? nodeA : nodeB
            if let index = discs.firstIndex(where: { $0.node === discNode }) {
                discs.remove(at: index)
            }
            discNode.removeFromParentNode()
            updateTiltFromDiscs()
            return
        }
    }
}

