import SwiftUI

/// SemanticTower のデザインシステム。
/// 「意味空間 = 宇宙空間」というメタファーでコスミックなテーマを統一。
enum STTheme {

    // MARK: - Colors

    enum Colors {
        static let cosmicDeep       = Color(red: 0.06, green: 0.04, blue: 0.16)
        static let cosmicMid        = Color(red: 0.12, green: 0.08, blue: 0.28)
        static let nebulaPurple     = Color(red: 0.38, green: 0.15, blue: 0.60)
        static let nebulaBlue       = Color(red: 0.18, green: 0.25, blue: 0.65)
        static let accentCyan       = Color(red: 0.30, green: 0.85, blue: 0.95)
        static let accentGold       = Color(red: 1.00, green: 0.82, blue: 0.30)
        static let accentPink       = Color(red: 0.95, green: 0.40, blue: 0.60)
        static let glassWhite       = Color.white.opacity(0.12)
        static let glassWhiteBorder = Color.white.opacity(0.25)
        static let textPrimary      = Color.white
        static let textSecondary    = Color.white.opacity(0.75)
        static let textTertiary     = Color.white.opacity(0.50)
        static let perfectGreen     = Color(red: 0.30, green: 0.95, blue: 0.55)
        static let niceYellow       = Color(red: 1.00, green: 0.85, blue: 0.25)
        static let missRed          = Color(red: 1.00, green: 0.35, blue: 0.35)
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
