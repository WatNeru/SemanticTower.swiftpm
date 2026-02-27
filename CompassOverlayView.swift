import SwiftUI

// MARK: - セマンティック座標 → マップ座標の変換

private struct MapCoordinateHelper {
    private static func spread(_ value: CGFloat) -> CGFloat {
        let absVal = min(1, abs(value))
        let scaled = 1 - (1 - absVal) * (1 - absVal)
        return value >= 0 ? scaled : -scaled
    }

    static func scaledSemantic(_ semantic: CGPoint) -> CGPoint {
        CGPoint(x: spread(CGFloat(semantic.x)), y: spread(CGFloat(semantic.y)))
    }

    static func mapPoint(semantic: CGPoint, in size: CGSize, padding: CGFloat = 24) -> CGPoint {
        let usableW = max(1, size.width - padding * 2)
        let usableH = max(1, size.height - padding * 2)
        let scaled = scaledSemantic(semantic)
        let posX = padding + usableW * (scaled.x + 1) / 2
        let posY = padding + usableH * (1 + scaled.y) / 2
        return CGPoint(x: posX, y: posY)
    }
}

// MARK: - Minimap (Compass)

struct CompassOverlayView: View {
    @ObservedObject var controller: SemanticGameController
    @ObservedObject var settings: GameSettings
    @State private var isExpanded = false

    var body: some View {
        Button {
            isExpanded = true
        } label: {
            miniMapContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isExpanded) {
            ExpandedMapView(controller: controller, settings: settings)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .accessibilityLabel("Semantic map. Tap to expand and see placed words.")
        .accessibilityHint("Double tap to open detailed map")
    }

    private var miniMapContent: some View {
        ZStack(alignment: .center) {
            crosshairLines

            axisLabel(initial(settings.anchorObject), color: STTheme.Colors.accentCyan)
                .offset(y: -26)
            axisLabel(initial(settings.anchorLiving), color: STTheme.Colors.accentGold)
                .offset(y: 26)
            axisLabel(initial(settings.anchorNature), color: STTheme.Colors.perfectBlue)
                .offset(x: 42)
            axisLabel(initial(settings.anchorMachine), color: STTheme.Colors.nebulaPurple)
                .offset(x: -42)

            if !controller.placedWords.isEmpty {
                targetIndicatorView
            }

            placedWordDots

            Circle()
                .fill(STTheme.Colors.textTertiary)
                .frame(width: 4, height: 4)
        }
        .frame(width: 110, height: 70)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 14, opacity: 0.10)
    }

    private var crosshairLines: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let halfW = size.width / 2 - 14
            let halfH = size.height / 2 - 10

            var hPath = Path()
            hPath.move(to: CGPoint(x: center.x - halfW, y: center.y))
            hPath.addLine(to: CGPoint(x: center.x + halfW, y: center.y))

            var vPath = Path()
            vPath.move(to: CGPoint(x: center.x, y: center.y - halfH))
            vPath.addLine(to: CGPoint(x: center.x, y: center.y + halfH))

            context.stroke(hPath, with: .color(.white.opacity(0.15)), lineWidth: 0.5)
            context.stroke(vPath, with: .color(.white.opacity(0.15)), lineWidth: 0.5)
        }
    }

    private func axisLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(color)
    }

    private func initial(_ word: String) -> String {
        String(word.prefix(1)).uppercased()
    }

    private var placedWordDots: some View {
        let mapCenterX: CGFloat = 55
        let mapCenterY: CGFloat = 35
        let mapScale: CGFloat = 22

        return ForEach(Array(controller.placedWords.suffix(8).enumerated()), id: \.offset) { _, item in
            let scaled = MapCoordinateHelper.scaledSemantic(item.position)
            let dotX = mapCenterX + scaled.x * mapScale
            let dotY = mapCenterY + scaled.y * mapScale
            Circle()
                .fill(SemanticColorHelper.swiftUIColor(for: item.position.x, semanticY: item.position.y))
                .frame(width: 5, height: 5)
                .position(x: dotX, y: dotY)
        }
    }

    private var targetIndicatorView: some View {
        let scaled = MapCoordinateHelper.scaledSemantic(controller.targetPosition)
        let mapCenterX: CGFloat = 55
        let mapCenterY: CGFloat = 35
        let mapScale: CGFloat = 22
        let targetX = mapCenterX - scaled.x * mapScale
        let targetY = mapCenterY + scaled.y * mapScale
        return ZStack {
            Circle()
                .stroke(STTheme.Colors.accentCyan.opacity(0.6), lineWidth: 1.5)
                .frame(width: 10, height: 10)
            Circle()
                .fill(STTheme.Colors.accentCyan.opacity(0.3))
                .frame(width: 6, height: 6)
        }
        .position(x: targetX, y: targetY)
    }
}

// MARK: - Expanded Map View

struct ExpandedMapView: View {
    @ObservedObject var controller: SemanticGameController
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)

                GeometryReader { geo in
                    let geoWidth = geo.size.width
                    let geoHeight = geo.size.height

                    gridLines(width: geoWidth, height: geoHeight)

                    Group {
                        expandedLabel(settings.anchorObject.capitalized, color: STTheme.Colors.accentCyan)
                            .position(x: geoWidth / 2, y: 16)
                        expandedLabel(settings.anchorLiving.capitalized, color: STTheme.Colors.accentGold)
                            .position(x: geoWidth / 2, y: geoHeight - 16)
                        expandedLabel(settings.anchorNature.capitalized, color: STTheme.Colors.perfectBlue)
                            .position(x: geoWidth - 28, y: geoHeight / 2)
                        expandedLabel(settings.anchorMachine.capitalized, color: STTheme.Colors.nebulaPurple)
                            .position(x: 32, y: geoHeight / 2)
                    }

                    ForEach(Array(controller.placedWords.enumerated()), id: \.offset) { _, item in
                        let point = MapCoordinateHelper.mapPoint(
                            semantic: item.position,
                            in: geo.size,
                            padding: 40
                        )
                        VStack(spacing: 2) {
                            Circle()
                                .fill(SemanticColorHelper.swiftUIColor(for: item.position.x, semanticY: item.position.y))
                                .frame(width: 12, height: 12)
                                .shadow(color: SemanticColorHelper.swiftUIColor(
                                    for: item.position.x, semanticY: item.position.y
                                ).opacity(0.5), radius: 4)
                            Text(item.word)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .position(point)
                    }

                    if !controller.placedWords.isEmpty {
                        let flippedTarget = CGPoint(
                            x: -controller.targetPosition.x,
                            y: controller.targetPosition.y
                        )
                        let point = MapCoordinateHelper.mapPoint(
                            semantic: flippedTarget,
                            in: geo.size,
                            padding: 40
                        )
                        ZStack {
                            Circle()
                                .stroke(STTheme.Colors.accentCyan, lineWidth: 2)
                                .frame(width: 18, height: 18)
                            Circle()
                                .fill(STTheme.Colors.accentCyan.opacity(0.2))
                                .frame(width: 14, height: 14)
                        }
                        .position(point)
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

    private func expandedLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(color)
    }

    private func gridLines(width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            let center = CGPoint(x: width / 2, y: height / 2)

            var hPath = Path()
            hPath.move(to: CGPoint(x: 40, y: center.y))
            hPath.addLine(to: CGPoint(x: width - 40, y: center.y))

            var vPath = Path()
            vPath.move(to: CGPoint(x: center.x, y: 40))
            vPath.addLine(to: CGPoint(x: center.x, y: height - 40))

            context.stroke(hPath, with: .color(.secondary.opacity(0.2)), lineWidth: 0.5)
            context.stroke(vPath, with: .color(.secondary.opacity(0.2)), lineWidth: 0.5)
        }
    }
}
