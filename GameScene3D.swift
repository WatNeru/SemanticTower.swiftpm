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
final class GameScene3D: NSObject, SCNPhysicsContactDelegate {
    let scene: SCNScene
    let cameraNode: SCNNode
    private var boardNode: SCNNode
    /// 傾き計算用にスムージングした重心（見かけ上の重心）。実際の重心にゆっくり追従させる。
    private var smoothedCenterOfMass: CGPoint = .zero
    private struct SemanticDisc {
        let node: SCNNode
        var isOnBoard: Bool
    }
    private var discs: [SemanticDisc] = []
    /// 重心を立て直すための最適落下位置マーカー（ボードの子ノード）
    private var targetMarkerNode: SCNNode?

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

        // 環境（CAGradientLayer はシミュレータの Metal でクラッシュするため単色を使用）
        // アクセシビリティ: ややニュートラル寄りの青で、ラベル・ディスクとのコントラストを確保
#if canImport(UIKit)
        scene.background.contents = UIColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1)
#else
        scene.background.contents = NSColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1)
#endif

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

        
        // 床（やや明るいグレーでボードのガラス感を際立たせる）
        let floor = SCNFloor()
        floor.reflectivity = 0.15
        let floorNode = SCNNode(geometry: floor)
#if canImport(UIKit)
        floorNode.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.25, alpha: 1)
#else
        floorNode.geometry?.firstMaterial?.diffuse.contents = NSColor(white: 0.25, alpha: 1)
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

        // 環境光を追加（ガラス表現の補助）
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 400
#if canImport(UIKit)
        ambientNode.light?.color = UIColor(white: 0.9, alpha: 1)
#else
        ambientNode.light?.color = NSColor(white: 0.9, alpha: 1)
#endif
        scene.rootNode.addChildNode(ambientNode)

        // ディスク移動に合わせて重心を定期的に更新する。
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTiltFromDiscs()
        }
    }

    /// セマンティック座標をボード上の位置にマッピングしてディスクを追加。
    /// position は [-1, 1] の範囲を想定。
    /// diskShape: .perfect = 正円（安定）, .nice = 歪んだ円盤（不安定）, .miss = 欠けた円盤（最も不安定）
    func addDisc(atSemanticPosition position: CGPoint, color: PlatformColor, mass: Double, diskShape: DiskShape = .perfect) {
        let baseRadius: CGFloat = 0.3
        let height: CGFloat = 0.2

        let geometry = SCNCylinder(radius: baseRadius, height: height)
        Self.applyDiscMaterial(to: geometry.firstMaterial, baseColor: color, diskShape: diskShape)

        let node = SCNNode(geometry: geometry)

        // 仕様: Perfect=正円, Nice=歪んだ円盤, Miss=欠けた円盤で物理的に不安定に
        switch diskShape {
        case .perfect:
            break  // そのまま正円
        case .nice:
            node.scale = SCNVector3(1.15, 1.0, 0.88)  // 楕円形に変形
        case .miss:
            node.scale = SCNVector3(1.25, 1.0, 0.75)  // より歪んで不安定
        }

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

    private static func applyDiscMaterial(to material: SCNMaterial?, baseColor: PlatformColor, diskShape: DiskShape) {
        guard let mat = material else { return }
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = baseColor
        mat.isDoubleSided = false
#if canImport(UIKit)
        switch diskShape {
        case .perfect:
            mat.specular.contents = UIColor(white: 0.8, alpha: 1)
            mat.roughness.contents = 0.08
            mat.metalness.contents = 0.05
        case .nice:
            mat.specular.contents = UIColor(white: 0.5, alpha: 1)
            mat.roughness.contents = 0.25
            mat.metalness.contents = 0.02
        case .miss:
            mat.specular.contents = UIColor(white: 0.2, alpha: 1)
            mat.roughness.contents = 0.6
            mat.metalness.contents = 0
        }
#else
        switch diskShape {
        case .perfect:
            mat.specular.contents = NSColor(white: 0.8, alpha: 1)
            mat.roughness.contents = 0.08
            mat.metalness.contents = 0.05
        case .nice:
            mat.specular.contents = NSColor(white: 0.5, alpha: 1)
            mat.roughness.contents = 0.25
            mat.metalness.contents = 0.02
        case .miss:
            mat.specular.contents = NSColor(white: 0.2, alpha: 1)
            mat.roughness.contents = 0.6
            mat.metalness.contents = 0
        }
#endif
    }

    private func addAnchorLabels() {
        // 大きく太いフォント（辺に平行・中心から読める向き）
        // アクセシビリティ: 明るい背景に対してWCAG 2.1 AA準拠の高コントラスト色を使用
        let font = UIFont.systemFont(ofSize: 0.6, weight: .bold)

        func makeTextNode(_ text: String) -> SCNNode {
            let textGeometry = SCNText(string: text, extrusionDepth: 0.03)
            textGeometry.font = font
            // ダークブルー: 明るい青背景(0.85,0.92,1.0)に対して視認性が高く、色覚多様性にも配慮
#if canImport(UIKit)
            let labelColor = UIColor(red: 0.12, green: 0.30, blue: 0.58, alpha: 1)
#else
            let labelColor = NSColor(red: 0.12, green: 0.30, blue: 0.58, alpha: 1)
#endif
            textGeometry.firstMaterial?.diffuse.contents = labelColor
            textGeometry.firstMaterial?.specular.contents = UIColor.white
            textGeometry.firstMaterial?.emission.contents = labelColor.withAlphaComponent(0.08)
            textGeometry.flatness = 0.1  // 滑らかな曲線
            let node = SCNNode(geometry: textGeometry)
            let (minVec, maxVec) = textGeometry.boundingBox
            let width = maxVec.x - minVec.x
            node.pivot = SCNMatrix4MakeTranslation((minVec.x + width / 2), minVec.y, 0)
            node.scale = SCNVector3(0.4, 0.4, 0.4)  // より大きく
            return node
        }

        // 各辺に平行に配置し、中心から正しい向きで読めるように回転
        // X軸右辺 (+X): 辺はZ方向 → 文字をZに平行、中心(-X)向き
        let natureNode = makeTextNode("Nature")
        natureNode.position = SCNVector3(3.2, 1.6, 0)
        natureNode.eulerAngles = SCNVector3(-Float.pi / 2, Float.pi / 2, 0)
        scene.rootNode.addChildNode(natureNode)

        // X軸左辺 (-X): 辺はZ方向 → 中心(+X)向き
        let machineNode = makeTextNode("Machine")
        machineNode.position = SCNVector3(-3.2, 1.6, 0)
        machineNode.eulerAngles = SCNVector3(-Float.pi / 2, -Float.pi / 2, 0)
        scene.rootNode.addChildNode(machineNode)

        // Z軸上辺 (+Z): 辺はX方向 → 文字をXに平行、中心(-Z)向き
        let livingNode = makeTextNode("Living")
        livingNode.position = SCNVector3(0, 1.6, 3.2)
        livingNode.eulerAngles = SCNVector3(-Float.pi / 2, Float.pi, 0)
        scene.rootNode.addChildNode(livingNode)

        // Z軸下辺 (-Z): 辺はX方向 → 中心(+Z)向き
        let objectNode = makeTextNode("Object")
        objectNode.position = SCNVector3(0, 1.6, -3.2)
        objectNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(objectNode)
    }

    /// 現在積まれているディスクのセマンティック重心から、盤の傾きを決める。
    /// 「実際の重心」を直接使わず、過去値との間を補間した `smoothedCenterOfMass` を使って
    /// 少しずつ傾くようにする。
    private func updateTiltFromDiscs() {
        let activeDiscs = discs.filter { $0.isOnBoard }
        let targetCenter: CGPoint

        if activeDiscs.isEmpty {
            // ディスクが無いときは「重心=原点」をターゲットとし、ゆっくり水平に戻る。
            targetCenter = .zero
        } else {
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
            targetCenter = CGPoint(x: centerX, y: centerY)
        }

        // 0 < alpha < 1: alpha が小さいほど、ゆっくり追従する。
        let alpha: CGFloat = 0.15
        smoothedCenterOfMass.x += (targetCenter.x - smoothedCenterOfMass.x) * alpha
        smoothedCenterOfMass.y += (targetCenter.y - smoothedCenterOfMass.y) * alpha

        updateBoardTilt(centerOfMass: smoothedCenterOfMass)
        updateTargetMarkerPosition(centerOfMass: smoothedCenterOfMass)
    }

    private func addTargetMarker() {
        // 薄い円環（トーラス）で「ここに落とす」を表示。横向き楕円状にスケール。
        // アクセシビリティ: 視認性の高いインディゴ系（アンカーラベルと調和しつつ区別可能）
        let torus = SCNTorus(ringRadius: 0.35, pipeRadius: 0.03)
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
    /// centerOfMass.x / y はともに [-1, 1] を想定。
    /// 「ターゲット角度」や補間は使わず、重心に対して即時に角度を決める。
    private func updateBoardTilt(centerOfMass: CGPoint) {
        let maxAngle: CGFloat = .pi / 3  // ≈60度
        let clampedX = max(-1.0, min(1.0, Double(centerOfMass.x)))
        let clampedY = max(-1.0, min(1.0, Double(centerOfMass.y)))

        let targetRollZ = -CGFloat(clampedX) * maxAngle
        let targetPitchX = CGFloat(clampedY) * maxAngle

        boardNode.eulerAngles.x = Float(targetPitchX)
        boardNode.eulerAngles.z = Float(targetRollZ)
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
            return
        }
    }
}

