import SwiftUI

/// ボードの傾き（意味的重心）をリアルタイム表示するミニマップ風インジケータ。
/// 4象限のアンカーラベル (Nature / Machine / Living / Object) とドットで重心を示す。
struct BalanceIndicator: View {
    let centerOfMass: CGPoint
    let discCount: Int

    private let indicatorSize: CGFloat = 100

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                gridBackground

                crosshair

                axisLabels

                balanceDot
            }
            .frame(width: indicatorSize, height: indicatorSize)
            .glassCard(cornerRadius: 16, opacity: 0.10)

            HStack(spacing: 4) {
                Image(systemName: "cube.fill")
                    .font(.system(size: 10))
                    .foregroundColor(STTheme.Colors.accentCyan)
                Text("\(discCount)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(STTheme.Colors.textSecondary)
            }
        }
    }

    private var gridBackground: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 12

            for ringFactor in [0.33, 0.66, 1.0] {
                let ringRadius = radius * ringFactor
                let rect = CGRect(
                    x: center.x - ringRadius,
                    y: center.y - ringRadius,
                    width: ringRadius * 2,
                    height: ringRadius * 2
                )
                context.stroke(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(0.08)),
                    lineWidth: 0.5
                )
            }
        }
    }

    private var crosshair: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let halfLen = min(size.width, size.height) / 2 - 12

            var hPath = Path()
            hPath.move(to: CGPoint(x: center.x - halfLen, y: center.y))
            hPath.addLine(to: CGPoint(x: center.x + halfLen, y: center.y))

            var vPath = Path()
            vPath.move(to: CGPoint(x: center.x, y: center.y - halfLen))
            vPath.addLine(to: CGPoint(x: center.x, y: center.y + halfLen))

            context.stroke(hPath, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
            context.stroke(vPath, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
        }
    }

    private var axisLabels: some View {
        ZStack {
            Text("N").position(x: indicatorSize - 10, y: indicatorSize / 2)
            Text("M").position(x: 10, y: indicatorSize / 2)
            Text("L").position(x: indicatorSize / 2, y: indicatorSize - 10)
            Text("O").position(x: indicatorSize / 2, y: 10)
        }
        .font(.system(size: 7, weight: .bold, design: .monospaced))
        .foregroundColor(STTheme.Colors.textTertiary)
    }

    private var balanceDot: some View {
        let halfSize = (indicatorSize / 2) - 16
        let clampedX = max(-1, min(1, centerOfMass.x))
        let clampedY = max(-1, min(1, centerOfMass.y))

        let dotX = indicatorSize / 2 + clampedX * halfSize
        let dotY = indicatorSize / 2 + clampedY * halfSize

        let dangerLevel = hypot(clampedX, clampedY)
        let dotColor: Color = dangerLevel > 0.7
            ? STTheme.Colors.missRed
            : dangerLevel > 0.4
                ? STTheme.Colors.niceYellow
                : STTheme.Colors.perfectGreen

        return ZStack {
            Circle()
                .fill(dotColor.opacity(0.3))
                .frame(width: 16, height: 16)

            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .glow(dotColor, radius: 4)
        }
        .position(x: dotX, y: dotY)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: centerOfMass.x)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: centerOfMass.y)
    }
}
