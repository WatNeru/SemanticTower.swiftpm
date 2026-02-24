import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// セマンティック座標（Nature↔Machine, Living↔Object）から色を算出するユーティリティ。
/// X軸: 緑系(Nature) ↔ 青/紫系(Machine)
/// Y軸: 暖色(Living) ↔ 冷色(Object) のブレンド
enum SemanticColorHelper {
#if canImport(UIKit)
    typealias PlatformColor = UIColor
#else
    typealias PlatformColor = NSColor
#endif

    /// セマンティック座標 (x, y) を [-1, 1] の範囲で受け取り、対応する色を返す。
    /// - Parameters:
    ///   - x: Nature(+1) ↔ Machine(-1)
    ///   - y: Living(+1) ↔ Object(-1)
    static func color(for x: CGFloat, y: CGFloat) -> PlatformColor {
        let clampedX = max(-1, min(1, x))
        let clampedY = max(-1, min(1, y))

        // X軸: Nature(緑系) ↔ Machine(青/紫系)
        // x=+1 → 緑, x=-1 → 青紫
        let natureGreen = PlatformColor(red: 0.2, green: 0.75, blue: 0.4, alpha: 1.0)
        let machineBlue = PlatformColor(red: 0.35, green: 0.45, blue: 0.85, alpha: 1.0)
        let xBlend = (clampedX + 1) / 2  // 0..1

        // Y軸: Living(暖色) ↔ Object(冷色) のブレンド係数
        let livingWarm = 0.7  // 暖色の強さ
        let objectCool = 0.3  // 冷色の強さ
        let yBlend = (clampedY + 1) / 2  // 0..1

        // 2軸を組み合わせて色を補間
        let baseX = lerpColor(natureGreen, machineBlue, t: xBlend)
        let warmTint = PlatformColor(red: 0.95, green: 0.7, blue: 0.4, alpha: 1.0)
        let coolTint = PlatformColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 1.0)
        let yTint = lerpColor(coolTint, warmTint, t: yBlend)

        return blendColors(baseX, yTint, amount: 0.35)
    }

    private static func lerpColor(_ a: PlatformColor, _ b: PlatformColor, t: CGFloat) -> PlatformColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let t = max(0, min(1, t))
        return PlatformColor(
            red: ar + (br - ar) * t,
            green: ag + (bg - ag) * t,
            blue: ab + (bb - ab) * t,
            alpha: aa + (ba - aa) * t
        )
    }

    private static func blendColors(_ base: PlatformColor, _ overlay: PlatformColor, amount: CGFloat) -> PlatformColor {
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        var or: CGFloat = 0, og: CGFloat = 0, ob: CGFloat = 0, oa: CGFloat = 0
        base.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        overlay.getRed(&or, green: &og, blue: &ob, alpha: &oa)
        let a = max(0, min(1, amount))
        return PlatformColor(
            red: br + (or - br) * a,
            green: bg + (og - bg) * a,
            blue: bb + (ob - bb) * a,
            alpha: 1
        )
    }
}
