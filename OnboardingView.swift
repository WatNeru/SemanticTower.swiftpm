import SwiftUI

/// 初回起動時のオンボーディング画面。
/// ゲームの世界観と遊び方を3ステップで伝え、
/// Swift Student Challenge 審査員の「最初の3分」を最大限に活かす。
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity: Double = 0
    @State private var pageOpacity: Double = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "Semantic Tower",
            subtitle: "Stack words by meaning",
            description: "Words are placed on a 2D semantic space\nusing AI word embeddings.\nSimilar words land near each other.",
            accentColor: STTheme.Colors.accentCyan
        ),
        OnboardingPage(
            icon: "scalemass",
            title: "Keep It Balanced",
            subtitle: "The board tilts with meaning",
            description: "The board tilts based on the semantic\ncenter of mass of stacked words.\nChoose wisely to stay balanced!",
            accentColor: STTheme.Colors.accentGold
        ),
        OnboardingPage(
            icon: "gamecontroller",
            title: "Let's Play",
            subtitle: "Demo or Manual mode",
            description: "Try Demo mode with preset words, or\nswitch to Manual to type or draw any word.\nBuild the tallest tower you can!",
            accentColor: STTheme.Colors.accentPink
        )
    ]

    var body: some View {
        ZStack {
            AnimatedBackground()

            VStack(spacing: 0) {
                Spacer()

                pageContent
                    .opacity(pageOpacity)

                Spacer()

                pageIndicator
                    .padding(.bottom, 20)

                navigationButton
                    .padding(.bottom, 50)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                pageOpacity = 1.0
            }
        }
    }

    private var pageContent: some View {
        let page = pages[currentPage]
        return VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .glow(page.accentColor, radius: 20)

                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(page.accentColor)
                    .scaleEffect(titleScale)
            }

            VStack(spacing: 8) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(STTheme.Colors.textPrimary)
                    .opacity(titleOpacity)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(page.accentColor)
            }

            Text(page.description)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(STTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
        }
        .id(currentPage)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage
                          ? pages[currentPage].accentColor
                          : STTheme.Colors.textTertiary)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4), value: currentPage)
            }
        }
    }

    private var navigationButton: some View {
        VStack(spacing: 12) {
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Start")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))

                    Image(systemName: currentPage < pages.count - 1
                          ? "arrow.right"
                          : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(STTheme.Colors.cosmicDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(pages[currentPage].accentColor)
                )
                .glow(pages[currentPage].accentColor, radius: 6)
            }
            .accessibilityLabel(currentPage < pages.count - 1 ? "Next page" : "Start game")

            if currentPage > 0 {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentPage -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(STTheme.Colors.textTertiary)
                }
                .accessibilityLabel("Previous page")
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color
}
