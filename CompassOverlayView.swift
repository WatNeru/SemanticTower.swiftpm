import SwiftUI

// MARK: - セマンティック座標 → マップ座標の変換
/// セマンティック空間 [-1, 1] × [-1, 1] をマップ上の座標に変換
/// 1 - (1-|x|)² でスケールし、中心に集まらないようにする
private struct MapCoordinateHelper {
    /// 中心を広げる非線形スケール: 1 - (1-|t|)²
    private static func spread(_ t: CGFloat) -> CGFloat {
        let absT = min(1, abs(t))
        let scaled = 1 - (1 - absT) * (1 - absT)
        return t >= 0 ? scaled : -scaled
    }

    /// スケール済みのセマンティック座標（中心に集まらないよう変換）
    static func scaledSemantic(_ semantic: CGPoint) -> CGPoint {
        CGPoint(x: spread(CGFloat(semantic.x)), y: spread(CGFloat(semantic.y)))
    }

    /// マップの表示範囲（パディング込み）。単語座標は中心に集まらないようスケール
    static func mapPoint(semantic: CGPoint, in size: CGSize, padding: CGFloat = 24) -> CGPoint {
        let usableW = max(1, size.width - padding * 2)
        let usableH = max(1, size.height - padding * 2)
        let scaled = scaledSemantic(semantic)
        let sx = scaled.x
        let sy = scaled.y
        // X: -1(Machine) → 左, +1(Nature) → 右
        // Y: -1(Object) → 下, +1(Living) → 上
        let x = padding + usableW * (sx + 1) / 2
        let y = padding + usableH * (1 - sy) / 2  // Y反転
        return CGPoint(x: x, y: y)
    }
}

// MARK: - 横書きラベル（中心から読める向き）
/// 左右のアンカー用。横書きで、中心から見て正しく読めるように180度回転して配置
private struct HorizontalAxisLabelCentered: View {
    let text: String
    var font: Font = .subheadline.weight(.bold)

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.primary)
            .rotationEffect(.degrees(180))
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
                .presentationDetents([.fraction(0.55), .large])
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
            // 左右のアンカー（横書き・中心から読める向きに180度回転）
            HorizontalAxisLabelCentered(text: "Nature")
                .offset(x: 36)
            HorizontalAxisLabelCentered(text: "Machine")
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

    /// ミニマップ内のターゲット位置（中心からの相対座標で配置、スケール適用）
    private var targetIndicatorView: some View {
        let scaled = MapCoordinateHelper.scaledSemantic(controller.targetPosition)
        let cx: CGFloat = 60
        let cy: CGFloat = 36
        let scale: CGFloat = 20
        let px = cx + scaled.x * scale
        let py = cy - scaled.y * scale
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

                // 軸ラベル（大きなマップ領域を確保）
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
                        HorizontalAxisLabelCentered(text: "Nature", font: .caption.weight(.bold))
                            .position(x: w - 24, y: h / 2)
                        HorizontalAxisLabelCentered(text: "Machine", font: .caption.weight(.bold))
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
            .frame(minWidth: 360, minHeight: 420)
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
