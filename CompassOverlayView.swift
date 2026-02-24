import SwiftUI

// MARK: - セマンティック座標 → マップ座標の変換
/// セマンティック空間 [-1, 1] × [-1, 1] をマップ上の座標に変換
private struct MapCoordinateHelper {
    /// マップの表示範囲（パディング込み）
    static func mapPoint(semantic: CGPoint, in size: CGSize, padding: CGFloat = 24) -> CGPoint {
        let usableW = max(1, size.width - padding * 2)
        let usableH = max(1, size.height - padding * 2)
        // X: -1(Machine) → 左, +1(Nature) → 右
        // Y: -1(Object) → 下, +1(Living) → 上
        let x = padding + usableW * (CGFloat(semantic.x) + 1) / 2
        let y = padding + usableH * (1 - CGFloat(semantic.y)) / 2  // Y反転
        return CGPoint(x: x, y: y)
    }
}

// MARK: - 縦書きラベル（内側から読める向き）
/// 左右のアンカー用。文字を縦に並べ、内側（中心）から正しく読める向きにする。
private struct VerticalAxisLabel: View {
    let text: String
    var font: Font = .subheadline.weight(.bold)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(text), id: \.self) { char in
                Text(String(char))
                    .font(font)
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - ミニマップ（コンパス風）
/// セマンティック軸を表示し、ターゲット位置を示す。タップで展開。
struct CompassOverlayView: View {
    @ObservedObject var controller: SemanticGameController
    @State private var isExpanded = false

    var body: some View {
        Button {
            isExpanded = true
        } label: {
            minishopContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isExpanded) {
            ExpandedMapView(controller: controller)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .accessibilityLabel("Semantic map. Tap to expand and see placed words.")
        .accessibilityHint("Double tap to open detailed map")
    }

    private var minishopContent: some View {
        ZStack(alignment: .center) {
            // 上下のアンカー（横書き）
            axisLabel("Living")
                .offset(y: -24)
            axisLabel("Object")
                .offset(y: 24)
            // 左右のアンカー（縦書き・内側から読める）
            VerticalAxisLabel(text: "Nature")
                .offset(x: 36)
            VerticalAxisLabel(text: "Machine")
                .offset(x: -36)

            // ターゲット位置のインジケータ（ディスクが1つ以上あるときのみ表示）
            if !controller.placedWords.isEmpty {
                targetIndicatorView
            }

            // 中心のコンパスローズ
            Circle()
                .strokeBorder(.secondary.opacity(0.4), lineWidth: 1)
                .frame(width: 8, height: 8)
        }
        .frame(width: 120, height: 72)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, cornerRadius: 16)
    }

    private func axisLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.primary)
    }

    /// ミニマップ内のターゲット位置（中心からの相対座標で配置）
    private var targetIndicatorView: some View {
        let cx: CGFloat = 60
        let cy: CGFloat = 36
        let scale: CGFloat = 20
        let px = cx + controller.targetPosition.x * scale
        let py = cy - controller.targetPosition.y * scale
        return Circle()
            .fill(.blue.opacity(0.85))
            .frame(width: 8, height: 8)
            .position(x: px, y: py)
    }
}

// MARK: - 展開マップ（配置履歴表示）
/// タップで展開。置いた単語の位置を表示する。
struct ExpandedMapView: View {
    @ObservedObject var controller: SemanticGameController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                // 背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)

                // 軸ラベル
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    Group {
                        Text("Living")
                            .font(.caption.weight(.bold))
                            .position(x: w / 2, y: 20)
                        Text("Object")
                            .font(.caption.weight(.bold))
                            .position(x: w / 2, y: h - 20)
                        VerticalAxisLabel(text: "Nature", font: .caption.weight(.bold))
                            .position(x: w - 24, y: h / 2)
                        VerticalAxisLabel(text: "Machine", font: .caption.weight(.bold))
                            .position(x: 24, y: h / 2)
                    }

                    // 配置単語のマーカー
                    ForEach(Array(controller.placedWords.enumerated()), id: \.offset) { _, item in
                        let pt = MapCoordinateHelper.mapPoint(
                            semantic: item.position,
                            in: geo.size,
                            padding: 40
                        )
                        VStack(spacing: 2) {
                            Circle()
                                .fill(SemanticColorHelper.swiftUIColor(for: item.position.x, y: item.position.y))
                                .frame(width: 10, height: 10)
                            Text(item.word)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .position(pt)
                    }

                    // ターゲット位置
                    if !controller.placedWords.isEmpty {
                        let pt = MapCoordinateHelper.mapPoint(
                            semantic: controller.targetPosition,
                            in: geo.size,
                            padding: 40
                        )
                        Circle()
                            .strokeBorder(.blue, lineWidth: 2)
                            .frame(width: 14, height: 14)
                            .position(pt)
                    }
                }
            }
            .padding(24)
            .navigationTitle("Semantic Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
