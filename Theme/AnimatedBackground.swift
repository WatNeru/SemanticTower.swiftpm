import SwiftUI

/// 意味空間を「宇宙空間」に見立てたアニメーション背景。
/// 星のパーティクル + ゆっくり動くネビュラグラデーションで奥行きを演出する。
struct AnimatedBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                drawNebula(context: context, size: size, time: time)
                drawStars(context: context, size: size, time: time)
            }
        }
        .background(STTheme.Colors.cosmicDeep)
        .ignoresSafeArea()
    }

    private func drawNebula(context: GraphicsContext, size: CGSize, time: Double) {
        let width = size.width
        let height = size.height

        let offsetX = CGFloat(sin(time * 0.05)) * width * 0.15
        let offsetY = CGFloat(cos(time * 0.03)) * height * 0.10

        var ctx = context
        ctx.opacity = 0.35

        let nebulaRect1 = CGRect(
            x: width * 0.2 + offsetX,
            y: height * 0.1 + offsetY,
            width: width * 0.6,
            height: height * 0.5
        )
        let gradient1 = Gradient(colors: [
            STTheme.Colors.nebulaPurple.opacity(0.4),
            STTheme.Colors.nebulaBlue.opacity(0.2),
            Color.clear
        ])
        ctx.fill(
            Ellipse().path(in: nebulaRect1),
            with: .radialGradient(
                gradient1,
                center: CGPoint(x: nebulaRect1.midX, y: nebulaRect1.midY),
                startRadius: 0,
                endRadius: max(nebulaRect1.width, nebulaRect1.height) * 0.5
            )
        )

        let nebulaRect2 = CGRect(
            x: width * 0.5 - offsetX * 0.7,
            y: height * 0.4 - offsetY * 0.5,
            width: width * 0.5,
            height: height * 0.4
        )
        let gradient2 = Gradient(colors: [
            STTheme.Colors.accentCyan.opacity(0.15),
            STTheme.Colors.nebulaPurple.opacity(0.1),
            Color.clear
        ])
        ctx.fill(
            Ellipse().path(in: nebulaRect2),
            with: .radialGradient(
                gradient2,
                center: CGPoint(x: nebulaRect2.midX, y: nebulaRect2.midY),
                startRadius: 0,
                endRadius: max(nebulaRect2.width, nebulaRect2.height) * 0.5
            )
        )
    }

    private func drawStars(context: GraphicsContext, size: CGSize, time: Double) {
        let starCount = 60
        for index in 0..<starCount {
            let seed = Double(index)
            let posX = fract(seed * 0.7654321) * size.width
            let posY = fract(seed * 0.3456789) * size.height

            let twinkle = (sin(time * (1.5 + seed * 0.3) + seed * 2.0) + 1.0) * 0.5
            let baseSize: CGFloat = CGFloat(fract(seed * 0.1234) * 2.0 + 0.5)
            let starSize = baseSize * CGFloat(0.4 + twinkle * 0.6)
            let starOpacity = 0.3 + twinkle * 0.7

            var ctx = context
            ctx.opacity = starOpacity

            let starRect = CGRect(
                x: posX - starSize / 2,
                y: posY - starSize / 2,
                width: starSize,
                height: starSize
            )
            ctx.fill(
                Ellipse().path(in: starRect),
                with: .color(.white)
            )

            if baseSize > 1.8 {
                var glowCtx = context
                glowCtx.opacity = starOpacity * 0.25
                let glowSize = starSize * 4
                let glowRect = CGRect(
                    x: posX - glowSize / 2,
                    y: posY - glowSize / 2,
                    width: glowSize,
                    height: glowSize
                )
                glowCtx.fill(
                    Ellipse().path(in: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.4), .clear]),
                        center: CGPoint(x: glowRect.midX, y: glowRect.midY),
                        startRadius: 0,
                        endRadius: glowSize / 2
                    )
                )
            }
        }
    }

    private func fract(_ value: Double) -> Double {
        value - floor(value)
    }
}
