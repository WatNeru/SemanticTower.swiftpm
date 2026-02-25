import SwiftUI

/// ゲームの進行状況をリアルタイムに表示するステータスバッジ。
/// タワーの高さ（単語数）、最高連続 Perfect 数、ボードバランスを可視化。
struct GameStatsView: View {
    let discCount: Int
    let perfectStreak: Int
    let isBalanced: Bool

    var body: some View {
        HStack(spacing: 14) {
            statItem(
                icon: "square.stack.3d.up.fill",
                value: "\(discCount)",
                label: "Tower",
                color: STTheme.Colors.accentCyan
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
                    ? STTheme.Colors.perfectGreen
                    : STTheme.Colors.missRed
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 14, opacity: 0.10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Tower height \(discCount), streak \(perfectStreak), balance \(isBalanced ? "OK" : "tilted")"
        )
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(STTheme.Colors.textPrimary)
            }
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundColor(STTheme.Colors.textTertiary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(STTheme.Colors.glassWhiteBorder)
            .frame(width: 0.5, height: 24)
    }
}
