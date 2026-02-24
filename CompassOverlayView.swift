import SwiftUI

/// セマンティック軸（Nature, Machine, Living, Object）をコンパス風に表示するオーバーレイ。
/// Liquid Glass パネル内に配置し、ゲーム画面上部に表示。
struct CompassOverlayView: View {
    var body: some View {
        ZStack(alignment: .center) {
            axisLabel("Living")
                .offset(y: -20)
            axisLabel("Object")
                .offset(y: 20)
            axisLabel("Nature")
                .offset(x: 28)
            axisLabel("Machine")
                .offset(x: -28)
        }
        .frame(width: 100, height: 60)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Semantic axes: Nature, Machine, Living, Object")
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}
