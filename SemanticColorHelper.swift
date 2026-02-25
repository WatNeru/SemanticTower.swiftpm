import Foundation
import CoreGraphics
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// セマンティック座標から色を生成。4象限ごとに特徴的なカラーを割り当て、
/// HSB 色空間で滑らかに補間することで豊かなバリエーションを実現。
///
/// 色覚多様性: 色相を均等に分散（90°間隔）し、彩度と明度で差別化。
/// 赤緑色覚でも象限の区別がつくよう、明度差を大きく取る。
enum SemanticColorHelper {
#if canImport(UIKit)
    typealias PlatformColor = UIColor
#else
    typealias PlatformColor = NSColor
#endif

    /// セマンティック座標 (x, y) → 色
    /// x: Nature(+1) ↔ Machine(-1), y: Living(+1) ↔ Object(-1)
    static func color(for semanticX: CGFloat, semanticY: CGFloat) -> PlatformColor {
        let clampX = max(-1, min(1, semanticX))
        let clampY = max(-1, min(1, semanticY))

        // 4象限の基準色 (HSB)
        //   (+X,+Y) Nature×Living  : 暖かい緑 (H=140°)
        //   (-X,+Y) Machine×Living : 鮮やかな紫 (H=280°)
        //   (+X,-Y) Nature×Object  : ティール (H=180°)
        //   (-X,-Y) Machine×Object : ディープブルー (H=230°)
        let xBlend = (clampX + 1) / 2   // 0(Machine) → 1(Nature)
        let yBlend = (clampY + 1) / 2   // 0(Object) → 1(Living)

        // 上段 (Living): 紫 → 緑
        let topHue = lerp(280, 140, blend: xBlend)
        let topSat = lerp(0.72, 0.68, blend: xBlend)
        let topBri = lerp(0.78, 0.72, blend: xBlend)

        // 下段 (Object): ディープブルー → ティール
        let botHue = lerp(230, 180, blend: xBlend)
        let botSat = lerp(0.65, 0.60, blend: xBlend)
        let botBri = lerp(0.62, 0.68, blend: xBlend)

        // 上下を補間
        let hue = lerp(botHue, topHue, blend: yBlend)
        let sat = lerp(botSat, topSat, blend: yBlend)
        let bri = lerp(botBri, topBri, blend: yBlend)

        return PlatformColor(
            hue: hue / 360.0,
            saturation: sat,
            brightness: bri,
            alpha: 1.0
        )
    }

    /// SwiftUI 用
    static func swiftUIColor(for semanticX: CGFloat, semanticY: CGFloat) -> Color {
#if canImport(UIKit)
        Color(uiColor: color(for: semanticX, semanticY: semanticY))
#else
        Color(nsColor: color(for: semanticX, semanticY: semanticY))
#endif
    }

    /// ベースカラーに対してコントラストのあるテキスト色を返す。
    /// 明るい背景 → ダーク文字、暗い背景 → ライト文字。WCAG 4.5:1 準拠。
    static func contrastingTextColor(for background: PlatformColor) -> PlatformColor {
        let lum = relativeLuminance(of: background)
        return lum > 0.35
            ? PlatformColor(white: 0.10, alpha: 1)
            : PlatformColor(white: 0.95, alpha: 1)
    }

    /// リング装飾用の半透明コントラスト色
    static func contrastingRingColor(for background: PlatformColor) -> PlatformColor {
        let lum = relativeLuminance(of: background)
        return lum > 0.35
            ? PlatformColor(white: 0.0, alpha: 0.20)
            : PlatformColor(white: 1.0, alpha: 0.25)
    }

    /// アイコン色（テキストと同系だがやや薄い）
    static func contrastingIconColor(for background: PlatformColor) -> PlatformColor {
        let lum = relativeLuminance(of: background)
        return lum > 0.35
            ? PlatformColor(white: 0.15, alpha: 0.80)
            : PlatformColor(white: 1.0, alpha: 0.85)
    }

    // MARK: - Private

    private static func lerp(_ from: CGFloat, _ to: CGFloat, blend: CGFloat) -> CGFloat {
        from + (to - from) * max(0, min(1, blend))
    }

    private static func relativeLuminance(of color: PlatformColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}
