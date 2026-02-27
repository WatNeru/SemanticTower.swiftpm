import SwiftUI

/// ディスクがボードから落ちたときのフィードバック表示。
struct FallNotificationView: View {
    let word: String
    let fallCount: Int

    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.system(size: 28))
                .foregroundColor(STTheme.Colors.missOrange)
                .rotationEffect(.degrees(shakeOffset * 3))

            Text("\"\(word)\" fell off!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(STTheme.Colors.missOrange)

            Text("Fallen: \(fallCount)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(STTheme.Colors.textTertiary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassCard(cornerRadius: 18, opacity: 0.15)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                opacity = 1
                yOffset = 0
            }
            withAnimation(
                .easeInOut(duration: 0.08)
                .repeatCount(5, autoreverses: true)
            ) {
                shakeOffset = 8
            }
            withAnimation(.easeIn(duration: 0.4).delay(2.0)) {
                opacity = 0
                yOffset = 30
            }
        }
    }
}
