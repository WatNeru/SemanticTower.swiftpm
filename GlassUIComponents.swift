import SwiftUI

// MARK: - Backported Glass Style (iOS 16+ 互換)

/// Liquid Glass (iOS 26+) と従来マテリアル (iOS 16–25) の両方に対応するスタイル。
/// Apple Swift Challenge で評価されるモダンなUIを実現。
enum GlassStyle {
    case regular
    case interactive
    case tinted(Color)
    case tintedInteractive(Color)

    var isInteractive: Bool {
        switch self {
        case .interactive, .tintedInteractive: return true
        default: return false
        }
    }

    var tintColor: Color? {
        switch self {
        case .tinted(let c), .tintedInteractive(let c): return c
        default: return nil
        }
    }

    func toLegacyMaterial() -> Material {
        switch self {
        case .regular: return .ultraThinMaterial
        case .interactive: return .thinMaterial
        case .tinted, .tintedInteractive: return .ultraThinMaterial
        }
    }
}

// MARK: - Glass Effect Modifier (iOS 26+ ネイティブ / 16–25 フォールバック)

private struct LegacyGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    let style: GlassStyle

    func body(content: Content) -> some View {
        content.background(
            ZStack {
                shape.fill(style.toLegacyMaterial())
                if let tintColor = style.tintColor {
                    shape.fill(tintColor.opacity(0.25))
                        .blendMode(.overlay)
                }
            }
        )
    }
}

@available(iOS 26.0, *)
private struct ModernGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    let style: GlassStyle

    func body(content: Content) -> some View {
        let glass: Glass = {
            var g: Glass = .regular
            if style.isInteractive { g = g.interactive() }
            if let tint = style.tintColor { g = g.tint(tint) }
            return g
        }()
        return content.glassEffect(glass, in: shape)
    }
}

extension View {
    /// Liquid Glass (iOS 26+) またはマテリアル (iOS 16–25) を適用。
    /// Apple Swift Challenge で評価されるリキッドグラス風UIを実現。
    @ViewBuilder
    func glassEffect<S: Shape>(
        _ style: GlassStyle = .regular,
        in shape: S
    ) -> some View {
        if #available(iOS 26.0, *) {
            modifier(ModernGlassModifier(shape: shape, style: style))
        } else {
            modifier(LegacyGlassModifier(shape: shape, style: style))
        }
    }

    /// 角丸四角形でガラス効果を適用（デフォルト cornerRadius: 16）
    @ViewBuilder
    func glassEffect(
        _ style: GlassStyle = .regular,
        cornerRadius: CGFloat = 16
    ) -> some View {
        glassEffect(style, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Button Style

/// ガラス風ボタンスタイル。iOS 26+ では Liquid Glass、それ以前ではマテリアルで表示。
struct GlassButtonStyle: ButtonStyle {
    let isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(isProminent ? .tinted(.accentColor) : .interactive, cornerRadius: 12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle(isProminent: false) }
    static var glassProminent: GlassButtonStyle { GlassButtonStyle(isProminent: true) }
}

// MARK: - Glass Panel (フローティングカード)

/// 3Dゲーム上に重ねるガラス風パネル。
struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .glassEffect(.regular, cornerRadius: 20)
    }
}

// MARK: - Glass TextField Style

/// ガラス風のテキストフィールドスタイル。
struct GlassTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular, cornerRadius: 14)
    }
}

extension View {
    func glassTextFieldStyle() -> some View {
        modifier(GlassTextFieldStyle())
    }
}
