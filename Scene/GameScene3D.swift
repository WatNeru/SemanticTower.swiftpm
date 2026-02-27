import SceneKit
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
typealias PlatformColor = UIColor
#else
typealias PlatformColor = NSColor
#endif

// MARK: - Sky Gradient

/// UIGraphicsImageRenderer で上→下の空グラデーション画像を生成。
private func createSkyGradientImage() -> UIImage {
    let size = CGSize(width: 1, height: 512)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        let colors: [CGColor] = [
            UIColor(red: 0.42, green: 0.58, blue: 0.82, alpha: 1).cgColor,
            UIColor(red: 0.62, green: 0.74, blue: 0.90, alpha: 1).cgColor,
            UIColor(red: 0.82, green: 0.82, blue: 0.88, alpha: 1).cgColor,
            UIColor(red: 0.90, green: 0.82, blue: 0.78, alpha: 1).cgColor
        ]
        let locations: [CGFloat] = [0.0, 0.35, 0.7, 1.0]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: locations
        ) {
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }
}

/// 認識精度に応じたディスク形状（仕様: Perfect=正円, Nice=歪み, Miss=欠け）
enum DiskShape {
    case perfect  // 安定した正円
    case nice     // 一部歪んだ円盤
    case miss     // 欠けた円盤（最も不安定）

    static func from(scoreRank: ScoreRank) -> DiskShape {
        switch scoreRank {
        case .perfect: return .perfect
        case .nice: return .nice
        case .miss: return .miss
        }
    }
}

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
}

/// タワーの土台を3Dで表現するシーン。
/// セマンティック重心に応じてボードを傾ける。
/// ドロップ系物理: kinematic ボード + dynamic ディスク、高摩擦・低反発でスタッキング安定化。
final class GameScene3D: NSObject, SCNPhysicsContactDelegate, @unchecked Sendable {
    let scene: SCNScene
    let cameraNode: SCNNode
    private var boardNode: SCNNode
    /// 傾き計算用にスムージングした重心（見かけ上の重心）。実際の重心にゆっくり追従させる。
    private(set) var smoothedCenterOfMass: CGPoint = .zero
    /// 傾き角度のスプリングアニメーション用: 現在の角速度
    private var tiltVelocityX: CGFloat = 0
    private var tiltVelocityZ: CGFloat = 0
    /// 傾き角度のスプリングアニメーション用: 現在の実際の角度
    private var currentPitchX: CGFloat = 0
    private var currentRollZ: CGFloat = 0

    /// UI から参照できるプロパティ。
    var currentCenterOfMass: CGPoint { smoothedCenterOfMass }
    var activeDiscCount: Int { discs.filter { $0.isOnBoard }.count }

    /// タワーの表示高さ（実測距離 × 10 でスコア的な数値に）
    var towerHeight: Float {
        let boardTopY: Float = 1.0 + 0.2
        let onBoard = discs.filter { $0.isOnBoard }
        guard !onBoard.isEmpty else { return 0 }
        let maxY = onBoard.map { $0.node.presentation.position.y }.max() ?? boardTopY
        return max(0, (maxY - boardTopY) * 10)
    }

    private struct SemanticDisc {
        let node: SCNNode
        let word: String
        var isOnBoard: Bool
    }
    private var discs: [SemanticDisc] = []

    /// 全ディスクを削除してリセット
    func resetBoard() {
        for disc in discs {
            disc.node.removeFromParentNode()
        }
        discs.removeAll()
        smoothedCenterOfMass = .zero
        currentPitchX = 0
        currentRollZ = 0
        tiltVelocityX = 0
        tiltVelocityZ = 0
        boardNode.eulerAngles = SCNVector3Zero
    }

    /// 重心を立て直すための最適落下位置マーカー（ボードの子ノード）
    private var targetMarkerNode: SCNNode?

    /// ミニマップ用: 最適落下位置（セマンティック座標 [-1,1]）が更新されたときに呼ばれる。
    var onTargetPositionUpdated: ((CGPoint) -> Void)?

    /// ディスクが床に落下したときに呼ばれる（単語名を通知）
    var onDiscFell: ((String) -> Void)?

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

        // 空の色: 夕暮れの穏やかなグラデーション感をプログラムで生成
        scene.background.contents = createSkyGradientImage()

        // カメラ
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 5, 9)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)
        scene.rootNode.addChildNode(cameraNode)

        // ライト
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(5, 8, 5)
        scene.rootNode.addChildNode(lightNode)

        // 床: 落ち着いた暖色系で空との調和を意識
        let floor = SCNFloor()
        floor.reflectivity = 0.25
        floor.reflectionFalloffEnd = 8.0
        let floorNode = SCNNode(geometry: floor)
        let floorMat = floor.firstMaterial ?? SCNMaterial()
#if canImport(UIKit)
        floorMat.diffuse.contents = UIColor(red: 0.22, green: 0.20, blue: 0.28, alpha: 1)
        floorMat.specular.contents = UIColor(white: 0.3, alpha: 1)
#else
        floorMat.diffuse.contents = NSColor(red: 0.22, green: 0.20, blue: 0.28, alpha: 1)
        floorMat.specular.contents = NSColor(white: 0.3, alpha: 1)
#endif
        floorMat.lightingModel = .physicallyBased
        floorMat.roughness.contents = 0.3
        floorMat.metalness.contents = 0.1
        // 床は静的な物理ボディ。低反発・高摩擦で落ちたディスクの跳ねを抑える。
        let floorBody = SCNPhysicsBody.static()
        floorBody.restitution = PhysicsConfig.restitution
        floorBody.friction = PhysicsConfig.friction
        floorBody.categoryBitMask = PhysicsCategory.floor
        floorBody.contactTestBitMask = PhysicsCategory.disc
        floorNode.physicsBody = floorBody
        // 盤面との距離感を出すために、床を低めに配置する。
        floorNode.position = SCNVector3(0, -3.0, 0)
        scene.rootNode.addChildNode(floorNode)

        // タワーの土台（傾ける板）— PBR ガラス風マテリアル
        let boardGeometry = SCNBox(width: 6, height: 0.4, length: 6, chamferRadius: 0.2)
        Self.applyGlassMaterial(to: boardGeometry.firstMaterial)
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
        addTargetMarker()

        // 環境光（温かみのあるトーン）
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 500
#if canImport(UIKit)
        ambientNode.light?.color = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)
#else
        ambientNode.light?.color = NSColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)
#endif
        scene.rootNode.addChildNode(ambientNode)

        // 上方向からの柔らかいライト（空の色を反映）
        let skyLightNode = SCNNode()
        skyLightNode.light = SCNLight()
        skyLightNode.light?.type = .directional
        skyLightNode.light?.intensity = 200
#if canImport(UIKit)
        skyLightNode.light?.color = UIColor(red: 0.75, green: 0.82, blue: 0.95, alpha: 1)
#else
        skyLightNode.light?.color = NSColor(red: 0.75, green: 0.82, blue: 0.95, alpha: 1)
#endif
        skyLightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        scene.rootNode.addChildNode(skyLightNode)

        // ディスク移動に合わせて重心を定期的に更新する。
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTiltFromDiscs()
        }
    }

    /// セマンティック座標をボード上の位置にマッピングしてディスクを追加。
    /// position は [-1, 1] の範囲を想定。
    /// diskShape: .perfect = 正円（安定）, .nice = 歪んだ円盤（不安定）, .miss = 欠けた円盤（最も不安定）
    func addDisc(
        atSemanticPosition position: CGPoint,
        color: PlatformColor,
        mass: Double,
        word: String = "",
        diskShape: DiskShape = .perfect
    ) {
        let baseRadius: CGFloat = 0.85
        let height: CGFloat = 0.3
        let shapeType = DiscShapeType.shape(for: word)

        // 親ノード: 透明な円柱（当たり判定専用、全形状共通）
        let collisionGeometry = SCNCylinder(radius: baseRadius, height: height)
        let invisibleMat = SCNMaterial()
        invisibleMat.diffuse.contents = PlatformColor.clear
        invisibleMat.transparency = 0
        collisionGeometry.materials = [invisibleMat]
        let node = SCNNode(geometry: collisionGeometry)

        // 子ノード: 見た目の形状（SCNShape で星・ハート・六角形など）
        let visualPath = shapeType.bezierPath(radius: baseRadius)
        let visualGeometry = SCNShape(path: visualPath, extrusionDepth: height)
        visualGeometry.chamferRadius = 0.04

        let texture = DiscTextureGenerator.generate(
            word: word,
            baseColor: color,
            diskShape: diskShape,
            shapeType: shapeType
        )
        DiscMaterialHelper.applyToShape(
            geometry: visualGeometry,
            baseColor: color,
            diskShape: diskShape,
            faceTexture: texture
        )

        let visualNode = SCNNode(geometry: visualGeometry)
        visualNode.eulerAngles.x = -.pi / 2
        visualNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(visualNode)

        switch diskShape {
        case .perfect:
            break
        case .nice:
            node.scale = SCNVector3(1.15, 1.0, 0.88)
        case .miss:
            node.scale = SCNVector3(1.25, 1.0, 0.75)
        }

        let localX = Float(max(-1.0, min(1.0, position.x))) * 2.6
        let localZ = Float(max(-1.0, min(1.0, position.y))) * 2.6
        let startY: Float = 5.0
        node.position = SCNVector3(localX, startY, localZ)

        // 当たり判定: 全形状共通の円柱（親ノードのジオメトリから自動生成）
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
        body.contactTestBitMask = PhysicsCategory.board | PhysicsCategory.floor | PhysicsCategory.disc
        node.physicsBody = body

        scene.rootNode.addChildNode(node)

        discs.append(
            SemanticDisc(node: node, word: word, isOnBoard: false)
        )
    }

    // MARK: - マテリアルヘルパー

    private static func applyGlassMaterial(to material: SCNMaterial?) {
        guard let mat = material else { return }
        mat.lightingModel = .physicallyBased
        mat.transparency = 0.85
        mat.transparencyMode = .dualLayer
        mat.fresnelExponent = 1.5
#if canImport(UIKit)
        mat.diffuse.contents = UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1)
        mat.specular.contents = UIColor(white: 0.6, alpha: 1)
        mat.metalness.contents = 0.1
        mat.roughness.contents = 0.05
#else
        mat.diffuse.contents = NSColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1)
        mat.specular.contents = NSColor(white: 0.6, alpha: 1)
        mat.metalness.contents = 0.1
        mat.roughness.contents = 0.05
#endif
        mat.isDoubleSided = true
    }

    // マテリアルは DiscMaterialHelper.applyToShape で直接適用

    /// 設定変更時にラベルを更新
    func updateAnchorLabels(settings: GameSettings) {
        scene.rootNode.childNodes
            .filter { $0.name?.hasPrefix("anchorLabel_") == true }
            .forEach { $0.removeFromParentNode() }
        addAnchorLabels(
            natureName: settings.anchorNature.capitalized,
            machineName: settings.anchorMachine.capitalized,
            livingName: settings.anchorLiving.capitalized,
            objectName: settings.anchorObject.capitalized
        )
    }

    private func addAnchorLabels(
        natureName: String = "Nature",
        machineName: String = "Machine",
        livingName: String = "Living",
        objectName: String = "Object"
    ) {
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all

        let font = UIFont.systemFont(ofSize: 0.6, weight: .bold)

        func makeTextNode(_ text: String, color: PlatformColor) -> SCNNode {
            let textGeometry = SCNText(string: text, extrusionDepth: 0.02)
            textGeometry.font = font
            textGeometry.flatness = 0.1
            textGeometry.firstMaterial?.diffuse.contents = color
            textGeometry.firstMaterial?.emission.contents = color.withAlphaComponent(0.15)
            textGeometry.firstMaterial?.isDoubleSided = true
            let node = SCNNode(geometry: textGeometry)
            let (minVec, maxVec) = textGeometry.boundingBox
            let textWidth = maxVec.x - minVec.x
            let textHeight = maxVec.y - minVec.y
            node.pivot = SCNMatrix4MakeTranslation(
                minVec.x + textWidth / 2,
                minVec.y + textHeight / 2,
                0
            )
            node.scale = SCNVector3(0.4, 0.4, 0.4)
            node.constraints = [billboard]
            return node
        }

#if canImport(UIKit)
        let natureColor = UIColor(red: 0.15, green: 0.72, blue: 0.38, alpha: 1)
        let machineColor = UIColor(red: 0.40, green: 0.30, blue: 0.75, alpha: 1)
        let livingColor = UIColor(red: 0.92, green: 0.68, blue: 0.20, alpha: 1)
        let objectColor = UIColor(red: 0.25, green: 0.65, blue: 0.88, alpha: 1)
#else
        let natureColor = NSColor(red: 0.15, green: 0.72, blue: 0.38, alpha: 1)
        let machineColor = NSColor(red: 0.40, green: 0.30, blue: 0.75, alpha: 1)
        let livingColor = NSColor(red: 0.92, green: 0.68, blue: 0.20, alpha: 1)
        let objectColor = NSColor(red: 0.25, green: 0.65, blue: 0.88, alpha: 1)
#endif

        let natureNode = makeTextNode(natureName, color: natureColor)
        natureNode.position = SCNVector3(3.4, 1.8, 0)
        natureNode.name = "anchorLabel_nature"
        scene.rootNode.addChildNode(natureNode)

        let machineNode = makeTextNode(machineName, color: machineColor)
        machineNode.position = SCNVector3(-3.4, 1.8, 0)
        machineNode.name = "anchorLabel_machine"
        scene.rootNode.addChildNode(machineNode)

        let livingNode = makeTextNode(livingName, color: livingColor)
        livingNode.position = SCNVector3(0, 1.8, 3.4)
        livingNode.name = "anchorLabel_living"
        scene.rootNode.addChildNode(livingNode)

        let objectNode = makeTextNode(objectName, color: objectColor)
        objectNode.position = SCNVector3(0, 1.8, -3.4)
        objectNode.name = "anchorLabel_object"
        scene.rootNode.addChildNode(objectNode)
    }

    /// 現在積まれているディスクのセマンティック重心から、盤の傾きを決める。
    ///
    /// 3段階のスムージング:
    ///  1. 重心の低速追従 (alpha = 0.08)
    ///  2. デッドゾーン: |重心| < 0.15 なら傾きゼロ（書く時間を確保）
    ///  3. スプリング補間: 角度はバネ的に目標に追従（急変しない）
    private func updateTiltFromDiscs() {
        let activeDiscs = discs.filter { $0.isOnBoard }
        let targetCenter: CGPoint

        if activeDiscs.isEmpty {
            targetCenter = .zero
        } else {
            let (sumX, sumY) = activeDiscs.reduce(into: (0.0, 0.0)) { acc, disc in
                let worldPos = disc.node.presentation.position
                let normalizedX = max(-1.0, min(1.0, Double(worldPos.x) / 2.5))
                let normalizedY = max(-1.0, min(1.0, Double(worldPos.z) / 2.5))
                acc.0 += normalizedX
                acc.1 += normalizedY
            }
            let count = Double(activeDiscs.count)
            targetCenter = CGPoint(x: sumX / count, y: sumY / count)
        }

        // 1. 重心の低速追従（以前は 0.15、ゆっくりに変更）
        let comAlpha: CGFloat = 0.08
        smoothedCenterOfMass.x += (targetCenter.x - smoothedCenterOfMass.x) * comAlpha
        smoothedCenterOfMass.y += (targetCenter.y - smoothedCenterOfMass.y) * comAlpha

        updateBoardTilt(centerOfMass: smoothedCenterOfMass)
        updateTargetMarkerPosition(centerOfMass: smoothedCenterOfMass)
        let targetPos = CGPoint(x: -smoothedCenterOfMass.x, y: -smoothedCenterOfMass.y)
        onTargetPositionUpdated?(targetPos)
    }

    private func addTargetMarker() {
        // 薄い円環（トーラス）で「ここに落とす」を表示。横向き楕円状にスケール。
        // アクセシビリティ: 視認性の高いインディゴ系（アンカーラベルと調和しつつ区別可能）
        let torus = SCNTorus(ringRadius: 0.6, pipeRadius: 0.04)
        let mat = SCNMaterial()
#if canImport(UIKit)
        let markerColor = UIColor(red: 0.35, green: 0.42, blue: 0.82, alpha: 1)
#else
        let markerColor = NSColor(red: 0.35, green: 0.42, blue: 0.82, alpha: 1)
#endif
        mat.diffuse.contents = markerColor.withAlphaComponent(0.9)
        mat.emission.contents = markerColor.withAlphaComponent(0.35)
        mat.transparency = 0.9
        torus.materials = [mat]
        let node = SCNNode(geometry: torus)
        // 円をボードと同じ向き（水平）にする。
        node.eulerAngles.x = 0
        node.position = SCNVector3(0, 0.21, 0)  // ボード上面よりわずかに上
        node.name = "targetMarker"
        boardNode.addChildNode(node)
        targetMarkerNode = node

        let pulseUp = SCNAction.scale(to: 1.3, duration: 0.8)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SCNAction.scale(to: 0.85, duration: 0.8)
        pulseDown.timingMode = .easeInEaseOut
        let pulse = SCNAction.sequence([pulseUp, pulseDown])
        node.runAction(SCNAction.repeatForever(pulse))
    }

    private func updateTargetMarkerPosition(centerOfMass: CGPoint) {
        guard let marker = targetMarkerNode else { return }
        // 重心の反対側が最適落下位置
        let targetX = Float(-centerOfMass.x) * 2.5
        let targetZ = Float(-centerOfMass.y) * 2.5
        marker.position = SCNVector3(targetX, 0.21, targetZ)
        // ディスクが無いときは非表示
        marker.isHidden = discs.filter { $0.isOnBoard }.isEmpty
    }

    /// セマンティック重心に応じて土台の傾き（X/Z軸回転）を更新。
    ///
    /// バランスゲームのベストプラクティス:
    ///  - デッドゾーン: 重心が中心付近なら傾き目標 = 0（プレイヤーに猶予）
    ///  - 最大傾き 25° に抑える（60° では即座に崩壊するため）
    ///  - スプリング補間: 角度が急変せず、バネのように自然に追従
    ///  - ダンピング: 振動を抑えて安定感を出す
    private func updateBoardTilt(centerOfMass: CGPoint) {
        let maxAngle: CGFloat = .pi / 7.2  // ≈25°
        let deadZone: CGFloat = 0.15
        let deltaTime: CGFloat = 0.1
        let springStiffness: CGFloat = 3.0
        let damping: CGFloat = 2.8

        // デッドゾーン適用: 中心付近は傾き目標ゼロ
        func applyDeadZone(_ val: CGFloat) -> CGFloat {
            let magnitude = abs(val)
            guard magnitude > deadZone else { return 0 }
            let effective = (magnitude - deadZone) / (1.0 - deadZone)
            return val >= 0 ? effective : -effective
        }

        let effectiveX = applyDeadZone(CGFloat(max(-1, min(1, centerOfMass.x))))
        let effectiveY = applyDeadZone(CGFloat(max(-1, min(1, centerOfMass.y))))

        let targetRollZ = -effectiveX * maxAngle
        let targetPitchX = effectiveY * maxAngle

        // スプリング補間: F = -k*(x - target) - d*v
        let forceX = -springStiffness * (currentPitchX - targetPitchX) - damping * tiltVelocityX
        let forceZ = -springStiffness * (currentRollZ - targetRollZ) - damping * tiltVelocityZ

        tiltVelocityX += forceX * deltaTime
        tiltVelocityZ += forceZ * deltaTime

        currentPitchX += tiltVelocityX * deltaTime
        currentRollZ += tiltVelocityZ * deltaTime

        boardNode.eulerAngles.x = Float(currentPitchX)
        boardNode.eulerAngles.z = Float(currentRollZ)
    }

    // MARK: - SCNPhysicsContactDelegate
    // SceneKit はレンダリングスレッドからデリゲートを呼ぶ。
    // Swift 6 では SCNNode を別スレッドに送れないため、
    // コールバック内で直接処理する（SceneKit 内部で同期済み）。

    nonisolated func physicsWorld(
        _ world: SCNPhysicsWorld,
        didBegin contact: SCNPhysicsContact
    ) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB

        let categoryA = nodeA.physicsBody?.categoryBitMask ?? 0
        let categoryB = nodeB.physicsBody?.categoryBitMask ?? 0

        if (categoryA == PhysicsCategory.disc && categoryB == PhysicsCategory.board) ||
            (categoryA == PhysicsCategory.board && categoryB == PhysicsCategory.disc) {
            let discNode = categoryA == PhysicsCategory.disc ? nodeA : nodeB
            let localPoint = boardNode.presentation.convertPosition(contact.contactPoint, from: nil)
            let (_, maxBounds) = boardNode.boundingBox
            if localPoint.y < maxBounds.y - 0.02 { return }

            if let index = discs.firstIndex(where: { $0.node === discNode }) {
                discNode.physicsBody?.velocity = SCNVector3Zero
                discNode.physicsBody?.angularVelocity = SCNVector4Zero
                let wasOffBoard = !discs[index].isOnBoard
                discs[index].isOnBoard = true
                if wasOffBoard {
                    SoundEngine.shared.playLand()
                }
            }
            return
        }

        // ディスク同士の接触 → 片方がボード上なら、もう片方もボード上とみなす
        if categoryA == PhysicsCategory.disc && categoryB == PhysicsCategory.disc {
            let idxA = discs.firstIndex(where: { $0.node === nodeA })
            let idxB = discs.firstIndex(where: { $0.node === nodeB })
            let aOnBoard = idxA.map { discs[$0].isOnBoard } ?? false
            let bOnBoard = idxB.map { discs[$0].isOnBoard } ?? false

            if aOnBoard, let ib = idxB, !discs[ib].isOnBoard {
                nodeB.physicsBody?.velocity = SCNVector3Zero
                nodeB.physicsBody?.angularVelocity = SCNVector4Zero
                discs[ib].isOnBoard = true
                SoundEngine.shared.playLand()
            }
            if bOnBoard, let ia = idxA, !discs[ia].isOnBoard {
                nodeA.physicsBody?.velocity = SCNVector3Zero
                nodeA.physicsBody?.angularVelocity = SCNVector4Zero
                discs[ia].isOnBoard = true
                SoundEngine.shared.playLand()
            }
            return
        }

        if (categoryA == PhysicsCategory.disc && categoryB == PhysicsCategory.floor) ||
            (categoryA == PhysicsCategory.floor && categoryB == PhysicsCategory.disc) {
            let discNode = categoryA == PhysicsCategory.disc ? nodeA : nodeB
            if let index = discs.firstIndex(where: { $0.node === discNode }) {
                let fallenWord = discs[index].word
                discs.remove(at: index)
                SoundEngine.shared.playFall()
                onDiscFell?(fallenWord)
            }
            discNode.removeFromParentNode()
            return
        }
    }
}

