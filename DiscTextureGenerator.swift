import UIKit

/// ディスク天面用のテクスチャ画像をプログラム生成。
/// 外部画像アセット不要。SSC 25MB 制限に影響しない。
enum DiscTextureGenerator {

    /// セマンティック座標に基づく色とテキストを含む円形テクスチャを生成。
    /// - Parameters:
    ///   - word: ディスクに刻む単語
    ///   - baseColor: ベースカラー（SemanticColorHelper から）
    ///   - diskShape: Perfect/Nice/Miss で質感を変える
    /// - Returns: 円形テクスチャの UIImage (256x256)
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

            // 円形クリッピング
            cgCtx.addEllipse(in: rect)
            cgCtx.clip()

            // ベースカラーで塗りつぶし
            cgCtx.setFillColor(baseColor.cgColor)
            cgCtx.fill(rect)

            // リング（縁取り）
            drawRing(cgCtx: cgCtx, center: center, radius: radius, diskShape: diskShape)

            // 中央にテキスト
            drawWord(word, in: rect, diskShape: diskShape)
        }
    }

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

        // Perfect には二重リングを追加
        if diskShape == .perfect {
            let innerRing = innerRect.insetBy(dx: 12, dy: 12)
            cgCtx.setLineWidth(2)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            cgCtx.strokeEllipse(in: innerRing)
        }
    }

    private static func drawWord(_ word: String, in rect: CGRect, diskShape: DiskShape) {
        let maxFontSize: CGFloat = word.count <= 4 ? 48 : word.count <= 7 ? 36 : 28
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
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (word as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
