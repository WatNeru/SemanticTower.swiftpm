import SpriteKit

/// 盤面がゆらゆらと揺れるデモ用の `SKScene`。
/// 後で `updateBoardTilt(centerOfMass:)` をゲームロジックから呼び出す想定。
final class GameScene: SKScene {
    private let boardNode = SKShapeNode(rectOf: CGSize(width: 400, height: 40), cornerRadius: 12)

    override func didMove(to view: SKView) {
        backgroundColor = .black

        boardNode.fillColor = .white
        boardNode.strokeColor = .clear
        boardNode.position = CGPoint(x: frame.midX, y: frame.midY)

        addChild(boardNode)

        // デモ用: 軽く左右にグラグラ揺れるアクション
        let maxAngle: CGFloat = .pi / 10 // 約18度
        let wobbleDuration: TimeInterval = 0.7

        let tiltRight = SKAction.rotate(toAngle: maxAngle, duration: wobbleDuration, shortestUnitArc: true)
        let tiltLeft = SKAction.rotate(toAngle: -maxAngle, duration: wobbleDuration, shortestUnitArc: true)
        let center = SKAction.rotate(toAngle: 0, duration: wobbleDuration, shortestUnitArc: true)

        let sequence = SKAction.sequence([tiltRight, center, tiltLeft, center])
        boardNode.run(SKAction.repeatForever(sequence))
    }

    /// セマンティック重心に応じて盤面の傾きを更新するためのAPI。
    /// centerOfMass は `[-1, 1]` の範囲で渡されることを想定。
    func updateBoardTilt(centerOfMass: CGPoint) {
        let maxAngle: CGFloat = .pi / 6 // 約30度
        let clampedX = max(-1.0, min(1.0, Double(centerOfMass.x)))
        let targetAngle = CGFloat(clampedX) * maxAngle

        let action = SKAction.rotate(toAngle: targetAngle, duration: 0.2, shortestUnitArc: true)
        action.timingMode = .easeOut
        boardNode.run(action)
    }
}

