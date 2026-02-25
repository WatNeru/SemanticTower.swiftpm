import UIKit

/// ディスク天面用のテクスチャ画像をプログラム生成。
/// 外部画像アセット不要。SF Symbols と Emoji は OS 内蔵。
enum DiscTextureGenerator {

    static func generate(
        word: String,
        baseColor: UIColor,
        diskShape: DiskShape
    ) -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2

            cgCtx.addEllipse(in: rect)
            cgCtx.clip()

            cgCtx.setFillColor(baseColor.cgColor)
            cgCtx.fill(rect)

            drawRing(cgCtx: cgCtx, center: center, radius: radius, diskShape: diskShape)

            drawIcon(word: word, in: rect, diskShape: diskShape)
            drawWord(word, in: rect, diskShape: diskShape)
        }
    }

    // MARK: - Ring decoration

    private static func drawRing(
        cgCtx: CGContext,
        center: CGPoint,
        radius: CGFloat,
        diskShape: DiskShape
    ) {
        let ringWidth: CGFloat
        let ringAlpha: CGFloat

        switch diskShape {
        case .perfect:
            ringWidth = 8
            ringAlpha = 0.25
        case .nice:
            ringWidth = 6
            ringAlpha = 0.15
        case .miss:
            ringWidth = 4
            ringAlpha = 0.10
        }

        cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(ringAlpha).cgColor)
        cgCtx.setLineWidth(ringWidth)
        let innerRect = CGRect(
            x: center.x - radius + ringWidth / 2,
            y: center.y - radius + ringWidth / 2,
            width: (radius - ringWidth / 2) * 2,
            height: (radius - ringWidth / 2) * 2
        )
        cgCtx.strokeEllipse(in: innerRect)

        if diskShape == .perfect {
            let secondRing = innerRect.insetBy(dx: 12, dy: 12)
            cgCtx.setLineWidth(2)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            cgCtx.strokeEllipse(in: secondRing)
        }
    }

    // MARK: - Icon (SF Symbol or Emoji)

    private static func drawIcon(word: String, in rect: CGRect, diskShape: DiskShape) {
        let iconAlpha: CGFloat = diskShape == .miss ? 0.5 : 0.85
        let iconSize: CGFloat = 64

        guard let iconImage = WordIconMapper.renderIcon(
            for: word,
            size: iconSize,
            color: UIColor.white.withAlphaComponent(iconAlpha)
        ) else { return }

        let iconRect = CGRect(
            x: (rect.width - iconSize) / 2,
            y: rect.height * 0.18,
            width: iconSize,
            height: iconSize
        )
        iconImage.draw(in: iconRect)
    }

    // MARK: - Word text

    private static func drawWord(_ word: String, in rect: CGRect, diskShape: DiskShape) {
        let maxFontSize: CGFloat = word.count <= 4 ? 36 : word.count <= 7 ? 28 : 22
        let font = UIFont.systemFont(ofSize: maxFontSize, weight: .bold)
        let textColor: UIColor

        switch diskShape {
        case .perfect:
            textColor = .white
        case .nice:
            textColor = UIColor.white.withAlphaComponent(0.85)
        case .miss:
            textColor = UIColor.white.withAlphaComponent(0.65)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = (word as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: rect.height * 0.62,
            width: textSize.width,
            height: textSize.height
        )
        (word as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
