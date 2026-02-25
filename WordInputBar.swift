import SwiftUI

/// 単語入力バー。グラスモーフィズムデザインのテキストフィールドと
/// グロウエフェクト付きの Drop ボタンを組み合わせる。
struct WordInputBar: View {
    @Binding var text: String
    let onDrop: () -> Void

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
                    .foregroundColor(STTheme.Colors.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16, opacity: 0.14)

            dropButton
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

}
