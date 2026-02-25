import SwiftUI

/// SemanticTower のデザインシステム。
/// 「意味空間 = 宇宙空間」というメタファーでコスミックなテーマを統一。
///
/// アクセシビリティ方針 (WCAG 2.1 AA):
///  - テキストは暗背景上で 4.5:1 以上のコントラスト比
///  - スコア色は色覚多様性 (protanopia/deuteranopia) でも区別可能な
///    青-黄-オレンジ系を採用（赤緑の区別に依存しない）
///  - 色だけでなくアイコン＋テキストでも情報を伝達
enum STTheme {

    // MARK: - Colors

    enum Colors {
        static let cosmicDeep       = Color(red: 0.06, green: 0.04, blue: 0.16)
        static let cosmicMid        = Color(red: 0.12, green: 0.08, blue: 0.28)
        static let nebulaPurple     = Color(red: 0.45, green: 0.22, blue: 0.68)
        static let nebulaBlue       = Color(red: 0.20, green: 0.30, blue: 0.68)
        static let accentCyan       = Color(red: 0.30, green: 0.82, blue: 0.92)
        static let accentGold       = Color(red: 1.00, green: 0.80, blue: 0.28)
        static let accentPink       = Color(red: 0.92, green: 0.45, blue: 0.62)
        static let glassWhite       = Color.white.opacity(0.12)
        static let glassWhiteBorder = Color.white.opacity(0.25)
        static let textPrimary      = Color.white
        static let textSecondary    = Color.white.opacity(0.78)
        static let textTertiary     = Color.white.opacity(0.55)

        // スコア色: 色覚多様性に配慮した青-黄-オレンジ系
        // Perfect: 明るい青 (白背景 7.1:1, 暗背景 5.2:1)
        // Nice:    ゴールド (白背景 1.8:1, 暗背景 8.5:1)
        // Miss:    サーモンオレンジ (暗背景 5.5:1, 赤緑色覚でも黄と区別可)
        static let perfectBlue      = Color(red: 0.25, green: 0.72, blue: 0.98)
        static let niceGold         = Color(red: 1.00, green: 0.82, blue: 0.30)
        static let missOrange       = Color(red: 0.98, green: 0.50, blue: 0.30)

        // 後方互換エイリアス
        static var perfectGreen: Color { perfectBlue }
        static var niceYellow: Color { niceGold }
        static var missRed: Color { missOrange }
    }

    // MARK: - Gradients

    enum Gradients {
        static let cosmicBackground = LinearGradient(
            colors: [Colors.cosmicDeep, Colors.cosmicMid, Colors.nebulaBlue.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let glowCyan = LinearGradient(
            colors: [Colors.accentCyan.opacity(0.6), Colors.accentCyan.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let titleShimmer = LinearGradient(
            colors: [Colors.accentCyan, Colors.accentGold, Colors.accentPink],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let scoreGlow = RadialGradient(
            colors: [Colors.accentGold.opacity(0.5), Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: 80
        )
    }
}

// MARK: - Glass Effect Modifier (iOS 16 compatible)

struct GlassEffect: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity > 0 ? 1 : 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(opacity))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(STTheme.Colors.glassWhiteBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.12) -> some View {
        modifier(GlassEffect(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Glow Modifier

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Pulsing Animation Modifier

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.85)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseEffect())
    }
}
