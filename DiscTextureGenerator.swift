import UIKit

/// ディスク天面用のテクスチャ画像をプログラム生成。
/// テキスト・アイコン・リングの色はベースカラーの明るさに応じて動的に決定。
enum DiscTextureGenerator {

    static func generate(
        word: String,
        baseColor: UIColor,
        diskShape: DiskShape,
        shapeType: DiscShapeType = .circle
    ) -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)

        let textColor = SemanticColorHelper.contrastingTextColor(for: baseColor)
        let iconColor = SemanticColorHelper.contrastingIconColor(for: baseColor)

        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // 常に正方形全体を描画。3D側の SCNShape が形をクリップする。
            drawBackground(cgCtx: cgCtx, rect: rect, baseColor: baseColor)
            drawIcon(word: word, in: rect, color: iconColor, diskShape: diskShape, shapeType: shapeType)
            drawWord(word, in: rect, color: textColor, diskShape: diskShape, shapeType: shapeType)
        }
    }

    // MARK: - Background with subtle gradient

    private static func drawBackground(
        cgCtx: CGContext,
        rect: CGRect,
        baseColor: UIColor
    ) {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        baseColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        let lighterColor = UIColor(hue: hue, saturation: max(0, sat - 0.08),
                                   brightness: min(1, bri + 0.12), alpha: 1)
        let darkerColor = UIColor(hue: hue, saturation: min(1, sat + 0.05),
                                  brightness: max(0, bri - 0.08), alpha: 1)

        let colors = [lighterColor.cgColor, darkerColor.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors, locations: [0.0, 1.0]) {
            cgCtx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: rect.midX * 0.7, y: rect.midY * 0.6),
                startRadius: 0,
                endCenter: CGPoint(x: rect.midX, y: rect.midY),
                endRadius: rect.width * 0.6,
                options: [.drawsAfterEndLocation]
            )
        }
    }

    // MARK: - Icon

    private static func drawIcon(
        word: String,
        in rect: CGRect,
        color: UIColor,
        diskShape: DiskShape,
        shapeType: DiscShapeType
    ) {
        let iconAlpha: CGFloat = diskShape == .miss ? 0.5 : 1.0
        let compact = shapeType == .star || shapeType == .heart || shapeType == .cloud
        let iconSize: CGFloat = compact ? 100 : 128
        let tintedColor = color.withAlphaComponent(iconAlpha)

        guard let iconImage = WordIconMapper.renderIcon(
            for: word, size: iconSize, color: tintedColor
        ) else { return }

        let iconY = compact ? rect.height * 0.22 : rect.height * 0.18
        let iconRect = CGRect(
            x: (rect.width - iconSize) / 2,
            y: iconY,
            width: iconSize,
            height: iconSize
        )
        iconImage.draw(in: iconRect)
    }

    // MARK: - Word text

    private static func drawWord(
        _ word: String,
        in rect: CGRect,
        color: UIColor,
        diskShape: DiskShape,
        shapeType: DiscShapeType
    ) {
        let compact = shapeType == .star || shapeType == .heart || shapeType == .cloud
        let fontSize: CGFloat
        if compact {
            fontSize = word.count <= 4 ? 52 : word.count <= 7 ? 40 : 30
        } else {
            fontSize = word.count <= 4 ? 64 : word.count <= 7 ? 48 : 36
        }
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)

        let alpha: CGFloat
        switch diskShape {
        case .perfect: alpha = 1.0
        case .nice:    alpha = 0.85
        case .miss:    alpha = 0.60
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color.withAlphaComponent(alpha),
            .paragraphStyle: paragraphStyle
        ]

        let textSize = (word as NSString).size(withAttributes: attributes)
        let textY = compact ? rect.height * 0.57 : rect.height * 0.62
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: textY,
            width: textSize.width,
            height: textSize.height
        )
        (word as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
