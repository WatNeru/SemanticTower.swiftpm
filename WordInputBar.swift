import SwiftUI

/// 単語入力バー。グラスモーフィズムデザインのテキストフィールドと
/// グロウエフェクト付きの Drop ボタンを組み合わせる。
struct WordInputBar: View {
    @Binding var text: String
    let isDemoMode: Bool
    let onDrop: () -> Void
    let onToggleMode: () -> Void

    @State private var isDropPressed = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "character.cursor.ibeam")
                    .foregroundColor(STTheme.Colors.textTertiary)
                    .font(.system(size: 14))

                TextField("type a word…", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(isDemoMode
                                     ? STTheme.Colors.textTertiary
                                     : STTheme.Colors.textPrimary)
                    .disabled(isDemoMode)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16, opacity: isDemoMode ? 0.06 : 0.14)

            dropButton

            modeToggle
        }
        .padding(.horizontal, 20)
    }

    private var dropButton: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isDropPressed = true
            }
            onDrop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isDropPressed = false
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Drop")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(STTheme.Colors.cosmicDeep)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(STTheme.Colors.accentCyan)
            )
            .scaleEffect(isDropPressed ? 0.9 : 1.0)
            .glow(STTheme.Colors.accentCyan, radius: isDropPressed ? 12 : 4)
        }
    }

    private var modeToggle: some View {
        Button {
            onToggleMode()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isDemoMode
                      ? "play.circle.fill"
                      : "keyboard")
                    .font(.system(size: 18))
                Text(isDemoMode ? "Demo" : "Manual")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isDemoMode
                             ? STTheme.Colors.accentGold
                             : STTheme.Colors.accentCyan)
            .frame(width: 50, height: 46)
            .glassCard(cornerRadius: 14, opacity: 0.12)
        }
    }
}
