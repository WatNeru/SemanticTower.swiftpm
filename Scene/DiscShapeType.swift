import UIKit

/// ディスクの外形バリエーション。単語のセマンティックカテゴリに応じて自動選択。
/// UIBezierPath → SCNShape で 3D ジオメトリ化する。
enum DiscShapeType: String, CaseIterable {
    case circle
    case star
    case heart
    case hexagon
    case diamond
    case flower
    case gear
    case cloud
    case rounded

    /// 半径 `radius` の UIBezierPath を生成（中心は原点）。
    func bezierPath(radius: CGFloat) -> UIBezierPath {
        let path: UIBezierPath
        switch self {
        case .circle:   path = Self.circlePath(radius: radius)
        case .star:     path = Self.starPath(radius: radius, points: 5, smoothness: 0.52)
        case .heart:    path = Self.heartPath(radius: radius)
        case .hexagon:  path = Self.polygonPath(radius: radius, sides: 6)
        case .diamond:  path = Self.polygonPath(radius: radius, sides: 4)
        case .flower:   path = Self.flowerPath(radius: radius, petals: 6)
        case .gear:     path = Self.gearPath(radius: radius, teeth: 8)
        case .cloud:    path = Self.cloudPath(radius: radius)
        case .rounded:  path = Self.roundedSquarePath(radius: radius)
        }
        path.flatness = 0.1
        return path
    }

    /// テクスチャ用のクリッピングパスを生成（テクスチャ座標 size×size 内、中心基準）。
    func texturePath(size: CGFloat) -> UIBezierPath {
        let path = bezierPath(radius: size / 2 - 8)
        let transform = CGAffineTransform(translationX: size / 2, y: size / 2)
        path.apply(transform)
        return path
    }

    // MARK: - Word → Shape mapping (delegated to WordDatabase)

    static func shape(for word: String) -> DiscShapeType {
        WordDatabase.shape(for: word)
    }
}

// MARK: - Path Generators

extension DiscShapeType {

    private static func circlePath(radius: CGFloat) -> UIBezierPath {
        UIBezierPath(
            arcCenter: .zero,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
    }

    private static func polygonPath(radius: CGFloat, sides: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let angleStep = (.pi * 2) / CGFloat(sides)
        let startAngle: CGFloat = -.pi / 2

        for idx in 0..<sides {
            let angle = startAngle + angleStep * CGFloat(idx)
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if idx == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }

    private static func starPath(radius: CGFloat, points: Int, smoothness: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let innerRadius = radius * smoothness
        let totalPoints = points * 2
        let angleStep = (.pi * 2) / CGFloat(totalPoints)
        let startAngle: CGFloat = -.pi / 2

        for idx in 0..<totalPoints {
            let angle = startAngle + angleStep * CGFloat(idx)
            let currentRadius = idx % 2 == 0 ? radius : innerRadius
            let point = CGPoint(x: cos(angle) * currentRadius, y: sin(angle) * currentRadius)
            if idx == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }

    private static func heartPath(radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let scale = radius / 50

        path.move(to: CGPoint(x: 0, y: 18 * scale))
        path.addCurve(
            to: CGPoint(x: -45 * scale, y: -20 * scale),
            controlPoint1: CGPoint(x: -5 * scale, y: -5 * scale),
            controlPoint2: CGPoint(x: -45 * scale, y: -5 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -45 * scale),
            controlPoint1: CGPoint(x: -45 * scale, y: -35 * scale),
            controlPoint2: CGPoint(x: -20 * scale, y: -45 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 45 * scale, y: -20 * scale),
            controlPoint1: CGPoint(x: 20 * scale, y: -45 * scale),
            controlPoint2: CGPoint(x: 45 * scale, y: -35 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: 18 * scale),
            controlPoint1: CGPoint(x: 45 * scale, y: -5 * scale),
            controlPoint2: CGPoint(x: 5 * scale, y: -5 * scale)
        )
        path.close()
        return path
    }

    private static func flowerPath(radius: CGFloat, petals: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let petalCount = petals
        let angleStep = (.pi * 2) / CGFloat(petalCount)
        let innerRadius = radius * 0.55

        for idx in 0..<petalCount {
            let baseAngle = angleStep * CGFloat(idx) - .pi / 2
            let midAngle = baseAngle + angleStep / 2
            let tipAngle = baseAngle + angleStep / 2

            let innerPoint = CGPoint(
                x: cos(baseAngle) * innerRadius,
                y: sin(baseAngle) * innerRadius
            )
            let tipPoint = CGPoint(
                x: cos(tipAngle) * radius,
                y: sin(tipAngle) * radius
            )
            let nextInnerPoint = CGPoint(
                x: cos(baseAngle + angleStep) * innerRadius,
                y: sin(baseAngle + angleStep) * innerRadius
            )
            let cp1 = CGPoint(
                x: cos(midAngle - 0.3) * radius * 0.9,
                y: sin(midAngle - 0.3) * radius * 0.9
            )
            let cp2 = CGPoint(
                x: cos(midAngle + 0.3) * radius * 0.9,
                y: sin(midAngle + 0.3) * radius * 0.9
            )

            if idx == 0 {
                path.move(to: innerPoint)
            }
            path.addCurve(to: tipPoint, controlPoint1: innerPoint, controlPoint2: cp1)
            path.addCurve(to: nextInnerPoint, controlPoint1: cp2, controlPoint2: nextInnerPoint)
        }
        path.close()
        return path
    }

    private static func gearPath(radius: CGFloat, teeth: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let outerRadius = radius
        let innerRadius = radius * 0.75
        let totalPoints = teeth * 2
        let angleStep = (.pi * 2) / CGFloat(totalPoints)
        let startAngle: CGFloat = -.pi / 2
        let toothHalfWidth: CGFloat = angleStep * 0.4

        for idx in 0..<teeth {
            let outerAngle = startAngle + angleStep * CGFloat(idx * 2)
            let innerAngle = startAngle + angleStep * CGFloat(idx * 2 + 1)

            let outerLeft = CGPoint(
                x: cos(outerAngle - toothHalfWidth) * outerRadius,
                y: sin(outerAngle - toothHalfWidth) * outerRadius
            )
            let outerRight = CGPoint(
                x: cos(outerAngle + toothHalfWidth) * outerRadius,
                y: sin(outerAngle + toothHalfWidth) * outerRadius
            )
            let innerLeft = CGPoint(
                x: cos(innerAngle - toothHalfWidth) * innerRadius,
                y: sin(innerAngle - toothHalfWidth) * innerRadius
            )
            let innerRight = CGPoint(
                x: cos(innerAngle + toothHalfWidth) * innerRadius,
                y: sin(innerAngle + toothHalfWidth) * innerRadius
            )

            if idx == 0 { path.move(to: outerLeft) }
            path.addLine(to: outerRight)
            path.addLine(to: innerLeft)
            path.addLine(to: innerRight)
        }
        path.close()
        return path
    }

    private static func cloudPath(radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let scl = radius / 50

        // 平底 + 3つの丸い盛り上がりで構成するシンプルな雲
        let baseY: CGFloat = 15 * scl

        path.move(to: CGPoint(x: -38 * scl, y: baseY))

        // 左の丸み
        path.addCurve(
            to: CGPoint(x: -20 * scl, y: -15 * scl),
            controlPoint1: CGPoint(x: -45 * scl, y: -5 * scl),
            controlPoint2: CGPoint(x: -35 * scl, y: -15 * scl)
        )
        // 中央の丸み（一番高い）
        path.addCurve(
            to: CGPoint(x: 20 * scl, y: -15 * scl),
            controlPoint1: CGPoint(x: -8 * scl, y: -42 * scl),
            controlPoint2: CGPoint(x: 8 * scl, y: -42 * scl)
        )
        // 右の丸み
        path.addCurve(
            to: CGPoint(x: 38 * scl, y: baseY),
            controlPoint1: CGPoint(x: 35 * scl, y: -15 * scl),
            controlPoint2: CGPoint(x: 45 * scl, y: -5 * scl)
        )
        // 平底
        path.addLine(to: CGPoint(x: -38 * scl, y: baseY))
        path.close()
        return path
    }

    private static func roundedSquarePath(radius: CGFloat) -> UIBezierPath {
        let side = radius * 1.5
        let cornerRadius = radius * 0.3
        return UIBezierPath(
            roundedRect: CGRect(x: -side / 2, y: -side / 2, width: side, height: side),
            cornerRadius: cornerRadius
        )
    }
}
