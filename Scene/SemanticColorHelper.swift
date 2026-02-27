import Foundation
import CoreGraphics
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// セマンティック座標から色を生成。
/// 4アンカー色を座標に基づく重みで混色し、明度を調整して見やすくする。
///
/// アンカー色（3Dラベルと統一）:
///   Nature (+X) : 緑   (0.15, 0.72, 0.38)
///   Machine(-X) : 紫   (0.40, 0.30, 0.75)
///   Living (+Y) : 金   (0.92, 0.68, 0.20)
///   Object (-Y) : 青   (0.25, 0.65, 0.88)
///
/// アクセシビリティ:
///   - 緑/紫 は色覚多様性でも明度差で区別可能
///   - 金/青 は全色覚タイプで区別しやすい組み合わせ
///   - 最終出力の明度を 0.55–0.82 に制限し、白文字・黒文字どちらでも読める
enum SemanticColorHelper {
#if canImport(UIKit)
    typealias PlatformColor = UIColor
#else
    typealias PlatformColor = NSColor
#endif

    // 4アンカー色（RGB）
    private static let natureRGB:  (r: CGFloat, g: CGFloat, b: CGFloat) = (0.15, 0.72, 0.38)
    private static let machineRGB: (r: CGFloat, g: CGFloat, b: CGFloat) = (0.40, 0.30, 0.75)
    private static let livingRGB:  (r: CGFloat, g: CGFloat, b: CGFloat) = (0.92, 0.68, 0.20)
    private static let objectRGB:  (r: CGFloat, g: CGFloat, b: CGFloat) = (0.25, 0.65, 0.88)

    /// セマンティック座標 → 色
    static func color(for semanticX: CGFloat, semanticY: CGFloat) -> PlatformColor {
        let clampX = max(-1, min(1, semanticX))
        let clampY = max(-1, min(1, semanticY))

        // X軸の重み: +1 → Nature 100%, -1 → Machine 100%
        let natureW  = max(0, clampX)         // 0...1
        let machineW = max(0, -clampX)        // 0...1

        // Y軸の重み: +1 → Living 100%, -1 → Object 100%
        let livingW  = max(0, clampY)         // 0...1
        let objectW  = max(0, -clampY)        // 0...1

        // 重みの合計（0になるのは原点のみ）
        let totalW = natureW + machineW + livingW + objectW

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat

        if totalW < 0.001 {
            // 原点: 4色の平均
            red   = (natureRGB.r + machineRGB.r + livingRGB.r + objectRGB.r) / 4
            green = (natureRGB.g + machineRGB.g + livingRGB.g + objectRGB.g) / 4
            blue  = (natureRGB.b + machineRGB.b + livingRGB.b + objectRGB.b) / 4
        } else {
            red   = (natureRGB.r * natureW + machineRGB.r * machineW
                   + livingRGB.r * livingW + objectRGB.r * objectW) / totalW
            green = (natureRGB.g * natureW + machineRGB.g * machineW
                   + livingRGB.g * livingW + objectRGB.g * objectW) / totalW
            blue  = (natureRGB.b * natureW + machineRGB.b * machineW
                   + livingRGB.b * livingW + objectRGB.b * objectW) / totalW
        }

        // 彩度を少し高めて視認性を上げる
        let boosted = boostSaturation(red: red, green: green, blue: blue, factor: 1.25)

        // 明度を 0.55–0.82 の範囲に制限（暗すぎず明るすぎず）
        let adjusted = adjustBrightness(
            red: boosted.red, green: boosted.green, blue: boosted.blue,
            minBrightness: 0.55, maxBrightness: 0.82
        )

        return PlatformColor(
            red: adjusted.red,
            green: adjusted.green,
            blue: adjusted.blue,
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

    /// ベースカラーに対してコントラストのあるテキスト色（WCAG 4.5:1 目標）
    static func contrastingTextColor(for background: PlatformColor) -> PlatformColor {
        let lum = relativeLuminance(of: background)
        return lum > 0.35
            ? PlatformColor(white: 0.08, alpha: 1)
            : PlatformColor(white: 0.97, alpha: 1)
    }

    static func contrastingRingColor(for background: PlatformColor) -> PlatformColor {
        let lum = relativeLuminance(of: background)
        return lum > 0.35
            ? PlatformColor(white: 0.0, alpha: 0.18)
            : PlatformColor(white: 1.0, alpha: 0.22)
    }

    static func contrastingIconColor(for background: PlatformColor) -> PlatformColor {
        let lum = relativeLuminance(of: background)
        return lum > 0.35
            ? PlatformColor(white: 0.12, alpha: 0.85)
            : PlatformColor(white: 1.0, alpha: 0.90)
    }

    // MARK: - Private

    private static func relativeLuminance(of color: PlatformColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private static func boostSaturation(
        red: CGFloat, green: CGFloat, blue: CGFloat, factor: CGFloat
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let gray = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let newR = max(0, min(1, gray + (red - gray) * factor))
        let newG = max(0, min(1, gray + (green - gray) * factor))
        let newB = max(0, min(1, gray + (blue - gray) * factor))
        return (newR, newG, newB)
    }

    private static func adjustBrightness(
        red: CGFloat, green: CGFloat, blue: CGFloat,
        minBrightness: CGFloat, maxBrightness: CGFloat
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let brightness = max(red, green, blue)
        guard brightness > 0.001 else {
            return (minBrightness, minBrightness, minBrightness)
        }
        let target: CGFloat
        if brightness < minBrightness {
            target = minBrightness
        } else if brightness > maxBrightness {
            target = maxBrightness
        } else {
            return (red, green, blue)
        }
        let scale = target / brightness
        return (
            min(1, red * scale),
            min(1, green * scale),
            min(1, blue * scale)
        )
    }
}
