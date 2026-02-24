import SwiftUI

/// セマンティック軸（Nature, Machine, Living, Object）をコンパス風に表示するオーバーレイ。
/// 3Dシーンの辺配置に合わせて横向きレイアウト。Liquid Glass パネル内に配置。
struct CompassOverlayView: View {
    var body: some View {
        ZStack(alignment: .center) {
            // 3Dボードの辺に対応: 上=Living, 下=Object, 右=Nature, 左=Machine
            axisLabel("Living")
                .offset(y: -24)
            axisLabel("Object")
                .offset(y: 24)
            axisLabel("Nature")
                .offset(x: 36)
            axisLabel("Machine")
                .offset(x: -36)
            // 中心の軽いインジケータ（コンパスローズ風）
            Circle()
                .strokeBorder(.secondary.opacity(0.4), lineWidth: 1)
                .frame(width: 8, height: 8)
        }
        .frame(width: 120, height: 72)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Semantic axes: Nature, Machine, Living, Object")
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.primary.opacity(0.9))
    }
}
