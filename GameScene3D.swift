import SceneKit
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - 物理パラメータ（ドロップ系スタッキングのベストプラクティス準拠）
// 参考: Stack Overflow "What SpriteKit physics properties are needed for stacking and balancing",
//       SceneKit friction/restitution, Kodeco SceneKit Physics Tutorial
private enum PhysicsConfig {
    /// 摩擦: 1.0 で最大の「くっつき」、オブジェクトがボードと一緒に動く
    static let friction: CGFloat = 1.0
    /// 反発: 0.05 で跳ねを抑え、スタッキングを安定させる
    static let restitution: CGFloat = 0.05
    /// 円柱の過剰な転がりを防ぐ（ディスク用）
    static let rollingFriction: CGFloat = 1.0
    /// 安定化のための減衰（0.05–0.1 が推奨）
    static let linearDamping: CGFloat = 0.1
    static let angularDamping: CGFloat = 0.1
    /// 傾きの角速度（ラジアン/秒）
    static let tiltAngularSpeed: CGFloat = .pi / 60  // 約3度/秒
}

/// タワーの土台を3Dで表現するシーン。
/// セマンティック重心に応じてボードを傾ける。
/// ドロップ系物理: kinematic ボード + dynamic ディスク、高摩擦・低反発でスタッキング安定化。
final class GameScene3D: NSObject, SCNPhysicsContactDelegate {
    let scene: SCNScene
    let cameraNode: SCNNode
    private var boardNode: SCNNode
    /// 現在の傾き（X=ピッチ, Z=ロール）。フレームごとに補間して physics と同期。
    private var currentPitchX: CGFloat = 0
    private var currentRollZ: CGFloat = 0
    private struct SemanticDisc {
        let node: SCNNode
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
        // 床は静的な物理ボディ。低反発・高摩擦で落ちたディスクの跳ねを抑える。
        let floorBody = SCNPhysicsBody.static()
        floorBody.restitution = PhysicsConfig.restitution
        floorBody.friction = PhysicsConfig.friction
        floorBody.categoryBitMask = PhysicsCategory.floor
        floorBody.contactTestBitMask = PhysicsCategory.disc
        floorNode.physicsBody = floorBody
        // 盤面との距離感を出すために、床を少し低めに配置する。
        floorNode.position = SCNVector3(0, -1.0, 0)
        scene.rootNode.addChildNode(floorNode)

        // タワーの土台（傾ける板）
        // 以前の当たり判定位置に近づけるため、高さを少し厚めに戻す。
        let boardGeometry = SCNBox(width: 6, height: 0.4, length: 6, chamferRadius: 0.2)
#if canImport(UIKit)
        boardGeometry.firstMaterial?.diffuse.contents = UIColor.white
#else
        boardGeometry.firstMaterial?.diffuse.contents = NSColor.white
#endif
        boardNode = SCNNode(geometry: boardGeometry)
        boardNode.position = SCNVector3(0, 1.0, 0)
        // 土台は kinematic: コードで傾きを制御し、その上に乗る dynamic オブジェクトと衝突する。
        // 高摩擦でディスクがボードと一緒に動く（position 移動時も friction が効く）。
        let boardBody = SCNPhysicsBody.kinematic()
        boardBody.restitution = PhysicsConfig.restitution
        boardBody.friction = PhysicsConfig.friction
        boardBody.categoryBitMask = PhysicsCategory.board
        boardBody.contactTestBitMask = PhysicsCategory.disc
        boardNode.physicsBody = boardBody
        scene.rootNode.addChildNode(boardNode)

        addAnchorLabels()

        // ディスク移動に合わせて重心を定期的に更新する。
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTiltFromDiscs()
        }
    }

    /// セマンティック座標をボード上の位置にマッピングしてディスクを追加。
    /// position は [-1, 1] の範囲を想定。
    func addDisc(atSemanticPosition position: CGPoint, color: UIColor, mass: Double) {
        let radius: CGFloat = 0.3
        let height: CGFloat = 0.2

        let geometry = SCNCylinder(radius: radius, height: height)
        geometry.firstMaterial?.diffuse.contents = color

        let node = SCNNode(geometry: geometry)

        // ボードは width=6, length=6。セマンティック座標を少し強調して左右に広げる。
        // [-1, 1] のセマンティックXを 4倍してから [-1, 1] に再クリップし、ボード半幅(≈3)の内側に収める。
        let semanticScaledX = max(-1.0, min(1.0, position.x * 4.0))
        let localX = Float(semanticScaledX) * 2.5
        let localZ = Float(position.y) * 2.5

        // 上の方から自由落下させるため、Y を高めに設定。
        let startY: Float = 4.0
        node.position = SCNVector3(localX, startY, localZ)

        // 動的な物理ボディ：スタッキング向けに高摩擦・低反発・高 rollingFriction。
        let body = SCNPhysicsBody.dynamic()
        body.mass = CGFloat(mass)
        body.restitution = PhysicsConfig.restitution
        body.friction = PhysicsConfig.friction
        body.rollingFriction = PhysicsConfig.rollingFriction  // 円柱の過剰な転がりを防ぐ
        body.angularDamping = PhysicsConfig.angularDamping
        body.damping = PhysicsConfig.linearDamping
        // すり抜け防止のため、ある程度の速さ以上で連続衝突判定を有効にする。
        body.continuousCollisionDetectionThreshold = 0.01
        body.categoryBitMask = PhysicsCategory.disc
        body.contactTestBitMask = PhysicsCategory.board | PhysicsCategory.floor
        node.physicsBody = body

        scene.rootNode.addChildNode(node)

        // まだ空中にあるので、ボードには乗っていない扱い（isOnBoard = false）
        discs.append(
            SemanticDisc(
                node: node,
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
        // 盤上ディスクの現在の物理位置から、上から見た X/Z を [-1, 1] に正規化して平均する。
        let (sumX, sumY) = activeDiscs.reduce(into: (0.0, 0.0)) { acc, disc in
            let worldPos = disc.node.presentation.position
            let worldX = Double(worldPos.x)
            let worldZ = Double(worldPos.z)
            // ボード半幅・半奥行きを 2.5 とみなして正規化。
            let normalizedX = max(-1.0, min(1.0, worldX / 2.5))
            let normalizedY = max(-1.0, min(1.0, worldZ / 2.5))
            acc.0 += normalizedX
            acc.1 += normalizedY
        }
        let count = Double(activeDiscs.count)
        let centerX = sumX / count
        let centerY = sumY / count
        let center = CGPoint(x: centerX, y: centerY)
        updateBoardTilt(centerOfMass: center)
    }

    /// セマンティック重心に応じて土台の傾き（X/Z軸回転）を更新。
    /// centerOfMass.x / y はともに [-1, 1] を想定。
    /// フレームごとに補間して更新し、physics エンジンと同期させる（SCNTransaction は避ける）。
    private func updateBoardTilt(centerOfMass: CGPoint) {
        let maxAngle: CGFloat = .pi / 3  // ≈60度
        let clampedX = max(-1.0, min(1.0, Double(centerOfMass.x)))
        let clampedY = max(-1.0, min(1.0, Double(centerOfMass.y)))

        let targetRollZ = -CGFloat(clampedX) * maxAngle
        let targetPitchX = CGFloat(clampedY) * maxAngle

        // 角速度に応じてフレームごとに補間（0.1秒間隔のタイマー想定）
        let dt: CGFloat = 0.1
        let maxDelta = PhysicsConfig.tiltAngularSpeed * dt

        func stepToward(current: CGFloat, target: CGFloat) -> CGFloat {
            let delta = target - current
            if abs(delta) < 0.001 { return target }
            let step = min(abs(delta), maxDelta) * (delta > 0 ? 1 : -1)
            return current + step
        }

        currentPitchX = stepToward(current: currentPitchX, target: targetPitchX)
        currentRollZ = stepToward(current: currentRollZ, target: targetRollZ)

        boardNode.eulerAngles.x = Float(currentPitchX)
        boardNode.eulerAngles.z = Float(currentRollZ)
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
            // ボードローカル座標系で接触点を見て、傾きに応じた「天面近傍」だけを盤上とみなす。
            let localPoint = boardNode.presentation.convertPosition(contact.contactPoint, from: nil)
            let (_, maxBounds) = boardNode.boundingBox
            let topY = maxBounds.y
            let epsilon: Float = 0.02
            // 側面や下面との接触は無視する。
            if localPoint.y < topY - epsilon {
                return
            }
            if let index = discs.firstIndex(where: { $0.node === discNode }) {
                // ボードに着地した瞬間の「ポン跳ね」を抑えるために速度を殺す。
                if let body = discNode.physicsBody {
                    body.velocity = SCNVector3Zero
                    body.angularVelocity = SCNVector4Zero
                }
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

