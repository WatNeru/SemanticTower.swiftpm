import SwiftUI

/// ゲームの進行状況をリアルタイムに表示するステータスバッジ。
struct GameStatsView: View {
    let discCount: Int
    let towerHeight: Float
    let perfectStreak: Int
    let isBalanced: Bool
    let fallCount: Int
    var largeText: Bool = false
    var highContrast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            statItem(
                icon: "square.stack.3d.up.fill",
                value: heightLabel,
                label: "Height",
                color: STTheme.Colors.accentCyan
            )

            divider

            statItem(
                icon: "cube.fill",
                value: "\(discCount)",
                label: "Discs",
                color: STTheme.Colors.textSecondary
            )

            divider

            statItem(
                icon: "flame.fill",
                value: "\(perfectStreak)",
                label: "Streak",
                color: perfectStreak >= 3
                    ? STTheme.Colors.accentGold
                    : STTheme.Colors.textTertiary
            )

            divider

            statItem(
                icon: isBalanced ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                value: isBalanced ? "OK" : "Tilt",
                label: "Balance",
                color: isBalanced
                    ? STTheme.Colors.perfectBlue
                    : STTheme.Colors.missOrange
            )

            if fallCount > 0 {
                divider

                statItem(
                    icon: "arrow.down.to.line",
                    value: "\(fallCount)",
                    label: "Fallen",
                    color: STTheme.Colors.missOrange
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 14, opacity: 0.10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Height \(heightLabel), \(discCount) discs, streak \(perfectStreak), \(isBalanced ? "balanced" : "tilted")"
        )
    }

    private var heightLabel: String {
        if towerHeight < 0.1 { return "0" }
        return String(format: "%.1f", towerHeight)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: largeText ? 13 : 10))
                    .foregroundColor(highContrast ? .white : color)
                Text(value)
                    .font(.system(size: largeText ? 15 : 12, weight: .bold, design: .monospaced))
                    .foregroundColor(highContrast ? .white : STTheme.Colors.textPrimary)
            }
            Text(label)
                .font(.system(size: largeText ? 9 : 7, weight: .medium, design: .rounded))
                .foregroundColor(highContrast ? .white.opacity(0.8) : STTheme.Colors.textTertiary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(STTheme.Colors.glassWhiteBorder)
            .frame(width: 0.5, height: 22)
    }
}
