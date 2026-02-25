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
        switch self {
        case .circle:   return Self.circlePath(radius: radius)
        case .star:     return Self.starPath(radius: radius, points: 5, smoothness: 0.45)
        case .heart:    return Self.heartPath(radius: radius)
        case .hexagon:  return Self.polygonPath(radius: radius, sides: 6)
        case .diamond:  return Self.polygonPath(radius: radius, sides: 4)
        case .flower:   return Self.flowerPath(radius: radius, petals: 6)
        case .gear:     return Self.gearPath(radius: radius, teeth: 8)
        case .cloud:    return Self.cloudPath(radius: radius)
        case .rounded:  return Self.roundedSquarePath(radius: radius)
        }
    }

    /// テクスチャ用のクリッピングパスを生成（テクスチャ座標 size×size 内、中心基準）。
    func texturePath(size: CGFloat) -> UIBezierPath {
        let path = bezierPath(radius: size / 2 - 4)
        let transform = CGAffineTransform(translationX: size / 2, y: size / 2)
        path.apply(transform)
        return path
    }

    // MARK: - Word → Shape mapping

    /// 単語からカテゴリを推定して形状を返す。
    static func shape(for word: String) -> DiscShapeType {
        let key = word.lowercased()
        if let direct = directMapping[key] { return direct }
        return categoryMapping(for: key)
    }

    // MARK: - Direct overrides

    private static let directMapping: [String: DiscShapeType] = [
        "love": .heart,
        "heart": .heart,
        "star": .star,
        "sun": .star,
        "moon": .star,
        "diamond": .diamond,
        "crown": .star,
        "flower": .flower,
        "garden": .flower,
        "cloud": .cloud,
        "dream": .cloud,
        "idea": .star,
        "magic": .star,
        "music": .flower
    ]

    /// 単語が属するカテゴリから形を返す
    private static func categoryMapping(for word: String) -> DiscShapeType {
        if animals.contains(word)  { return .hexagon }
        if nature.contains(word)   { return .flower }
        if machines.contains(word) { return .gear }
        if objects.contains(word)  { return .diamond }
        if emotions.contains(word) { return .heart }
        if abstract.contains(word) { return .star }
        return .circle
    }

    private static let animals: Set<String> = [
        "dog", "cat", "lion", "eagle", "whale", "bird", "fish",
        "rabbit", "hare", "ant", "bear", "horse", "elephant",
        "tiger", "monkey", "snake", "turtle", "bug", "wolf",
        "fox", "penguin", "butterfly", "cow", "pig", "sheep",
        "deer", "frog", "animal"
    ]

    private static let nature: Set<String> = [
        "tree", "river", "mountain", "forest", "ocean", "leaf",
        "rain", "snow", "wind", "fire", "earth", "sky",
        "volcano", "island", "nature"
    ]

    private static let machines: Set<String> = [
        "car", "train", "airplane", "computer", "robot", "phone",
        "camera", "rocket", "bicycle", "bus", "ship", "helicopter",
        "engine", "battery", "satellite", "drone", "machine"
    ]

    private static let objects: Set<String> = [
        "stone", "chair", "table", "book", "key", "clock",
        "lamp", "cup", "ball", "hammer", "guitar", "bell",
        "pen", "bag", "gift", "shield", "sword", "ring", "object"
    ]

    private static let emotions: Set<String> = [
        "happy", "sad", "angry", "calm", "excited", "fear",
        "surprise", "hope", "joy", "peace", "pride", "human"
    ]

    private static let abstract: Set<String> = [
        "freedom", "justice", "power", "time", "art", "science",
        "wisdom", "courage", "truth", "beauty", "chaos", "energy"
    ]
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
        let innerRadius = radius * 0.72
        let toothWidth: CGFloat = .pi / CGFloat(teeth) * 0.6

        for idx in 0..<teeth {
            let baseAngle = (.pi * 2 / CGFloat(teeth)) * CGFloat(idx) - .pi / 2

            let outerStart = CGPoint(
                x: cos(baseAngle - toothWidth / 2) * outerRadius,
                y: sin(baseAngle - toothWidth / 2) * outerRadius
            )
            let outerEnd = CGPoint(
                x: cos(baseAngle + toothWidth / 2) * outerRadius,
                y: sin(baseAngle + toothWidth / 2) * outerRadius
            )

            let nextBase = (.pi * 2 / CGFloat(teeth)) * CGFloat(idx + 1) - .pi / 2
            let innerStart = CGPoint(
                x: cos(baseAngle + toothWidth / 2) * innerRadius,
                y: sin(baseAngle + toothWidth / 2) * innerRadius
            )
            let innerEnd = CGPoint(
                x: cos(nextBase - toothWidth / 2) * innerRadius,
                y: sin(nextBase - toothWidth / 2) * innerRadius
            )

            if idx == 0 { path.move(to: outerStart) }
            path.addLine(to: outerEnd)
            path.addLine(to: innerStart)
            path.addLine(to: innerEnd)
            path.addLine(to: CGPoint(
                x: cos(nextBase - toothWidth / 2) * outerRadius,
                y: sin(nextBase - toothWidth / 2) * outerRadius
            ))
        }
        path.close()
        return path
    }

    private static func cloudPath(radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let scale = radius / 50

        path.move(to: CGPoint(x: -35 * scale, y: 10 * scale))
        path.addCurve(
            to: CGPoint(x: -30 * scale, y: -20 * scale),
            controlPoint1: CGPoint(x: -45 * scale, y: -5 * scale),
            controlPoint2: CGPoint(x: -42 * scale, y: -20 * scale)
        )
        path.addCurve(
            to: CGPoint(x: -5 * scale, y: -35 * scale),
            controlPoint1: CGPoint(x: -22 * scale, y: -35 * scale),
            controlPoint2: CGPoint(x: -12 * scale, y: -40 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 25 * scale, y: -25 * scale),
            controlPoint1: CGPoint(x: 5 * scale, y: -42 * scale),
            controlPoint2: CGPoint(x: 18 * scale, y: -35 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 40 * scale, y: -5 * scale),
            controlPoint1: CGPoint(x: 38 * scale, y: -22 * scale),
            controlPoint2: CGPoint(x: 45 * scale, y: -15 * scale)
        )
        path.addCurve(
            to: CGPoint(x: 35 * scale, y: 15 * scale),
            controlPoint1: CGPoint(x: 48 * scale, y: 5 * scale),
            controlPoint2: CGPoint(x: 42 * scale, y: 12 * scale)
        )
        path.addLine(to: CGPoint(x: -35 * scale, y: 15 * scale))
        path.addCurve(
            to: CGPoint(x: -35 * scale, y: 10 * scale),
            controlPoint1: CGPoint(x: -38 * scale, y: 15 * scale),
            controlPoint2: CGPoint(x: -38 * scale, y: 12 * scale)
        )
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
