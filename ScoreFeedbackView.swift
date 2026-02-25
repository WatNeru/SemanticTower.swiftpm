import SwiftUI

/// 単語ドロップ時にアニメーション付きで表示されるスコアフィードバック。
/// Perfect / Nice / Miss を視覚的にフィードバックしてゲーム体験を盛り上げる。
struct ScoreFeedbackView: View {
    let score: ScoreResult
    let word: String
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 20
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(rankColor.opacity(0.4), lineWidth: 2)
                .frame(width: 150, height: 150)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 6) {
                Text(rankEmoji)
                    .font(.system(size: 40))

                Text(rankLabel)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(rankColor)
                    .glow(rankColor, radius: 10)

                Text("\"\(word)\"")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(STTheme.Colors.textSecondary)

                Text("\(Int(score.accuracy * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(rankColor.opacity(0.8))
            }
            .padding(24)
            .glassCard(cornerRadius: 24, opacity: 0.15)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
                yOffset = 0
            }
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 2.0
                ringOpacity = 0.8
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                ringOpacity = 0
            }
            withAnimation(.easeIn(duration: 0.3).delay(1.8)) {
                opacity = 0
                scale = 0.8
                yOffset = -30
            }
        }
    }

    private var rankLabel: String {
        switch score.rank {
        case .perfect: return "Perfect!"
        case .nice: return "Nice!"
        case .miss: return "Miss…"
        }
    }

    private var rankEmoji: String {
        switch score.rank {
        case .perfect: return "✨"
        case .nice: return "👍"
        case .miss: return "💨"
        }
    }

    private var rankColor: Color {
        switch score.rank {
        case .perfect: return STTheme.Colors.perfectGreen
        case .nice: return STTheme.Colors.niceYellow
        case .miss: return STTheme.Colors.missRed
        }
    }
}

/// デモモードで単語がドロップされたときの軽量フィードバック。
struct WordDropFeedback: View {
    let word: String
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(STTheme.Colors.accentCyan)
                .font(.system(size: 14))

            Text(word)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(STTheme.Colors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 14, opacity: 0.18)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                opacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.3).delay(1.2)) {
                opacity = 0
                yOffset = -20
            }
        }
    }
}
