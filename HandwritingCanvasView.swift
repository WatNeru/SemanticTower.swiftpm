import SwiftUI
import PencilKit

// MARK: - タッチを確実にキャンバスに渡すコンテナ（SwiftUI のヒットテスト不具合対策）
final class CanvasHostView: UIView {
    let canvasView: PKCanvasView

    init(canvasView: PKCanvasView) {
        self.canvasView = canvasView
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        addSubview(canvasView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        canvasView.frame = bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        // 自分に当たった場合はキャンバスに渡す（指・ペンの描画を確実に受けさせる）
        if hit == self, bounds.contains(point) {
            return canvasView.hitTest(canvasView.convert(point, from: self), with: event) ?? canvasView
        }
        return hit
    }
}

/// PencilKit ベースの手書き入力キャンバス。
/// Apple Pencil と指の両方に対応。白背景・黒線で Vision 認識精度を最大化。
struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var canvasSize: CGSize = CGSize(width: 400, height: 120)

    func makeUIView(context: Context) -> CanvasHostView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        // 指・Apple Pencil・第三者のスタイラスすべてで描画できるようにする
        canvas.drawingPolicy = .anyInput
        canvas.allowsFingerDrawing = true
        canvas.backgroundColor = .white
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        // Metal / SceneView 上でも確実に描画が見えるよう、不透明レイヤとして扱う
        canvas.isOpaque = true
        canvas.isScrollEnabled = false
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        canvas.isMultipleTouchEnabled = true
        canvas.isUserInteractionEnabled = true
        return CanvasHostView(canvasView: canvas)
    }

    func updateUIView(_ uiView: CanvasHostView, context: Context) {
        let canvas = uiView.canvasView
        guard !context.coordinator.isUpdating else { return }
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        var isUpdating = false

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdating = true
            DispatchQueue.main.async { [weak self] in
                print("[HandwritingCanvasView] drawing changed, bounds=\(canvasView.drawing.bounds)")
                self?.drawing = canvasView.drawing
                self?.isUpdating = false
            }
        }
    }
}

// MARK: - Vision input image

extension HandwritingCanvasView {
    static func image(from drawing: PKDrawing, size: CGSize, scale: CGFloat = 2.0) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let img = drawing.image(from: rect, scale: scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(rect)
            img.draw(in: rect)
        }
    }
}

// MARK: - Polished handwriting input panel

/// 手書き入力エリア全体を構成するコンポーネント。
/// キャンバス + ガイド + アクションボタンをまとめて提供。
struct HandwritingInputPanel: View {
    @ObservedObject var controller: SemanticGameController
    let onDrop: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            canvasArea
            recognitionFeedback
            controlBar
        }
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        ZStack(alignment: .center) {
            // ガイド・プレースホルダーは下層（ヒットテスト無効）
            baselineGuide
            if controller.handwritingDrawing.bounds.isEmpty && !controller.isDemoMode {
                Text("Write a word here")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.gray.opacity(0.4))
                    .allowsHitTesting(false)
            }
            // キャンバスを最前面にし、タッチを確実に受けさせる（contentShape は付けない）
            HandwritingCanvasView(
                drawing: $controller.handwritingDrawing,
                canvasSize: CGSize(width: 340, height: 120)
            )
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
            .disabled(controller.isDemoMode)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(canvasBorderColor, lineWidth: 1.5)
        )
    }

    private var baselineGuide: some View {
        GeometryReader { geo in
            Path { path in
                let baseY = geo.size.height * 0.72
                path.move(to: CGPoint(x: 16, y: baseY))
                path.addLine(to: CGPoint(x: geo.size.width - 16, y: baseY))
            }
            .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        }
        .allowsHitTesting(false)
    }

    private var canvasBorderColor: Color {
        if controller.isRecognizing {
            return STTheme.Colors.accentCyan
        }
        if controller.handwritingDrawing.bounds.isEmpty {
            return Color.gray.opacity(0.2)
        }
        return STTheme.Colors.accentCyan.opacity(0.5)
    }

    // MARK: - Recognition feedback

    @ViewBuilder
    private var recognitionFeedback: some View {
        if controller.isRecognizing {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Recognizing…")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(STTheme.Colors.textTertiary)
            }
        } else if let rec = controller.lastRecognitionResult, !rec.text.isEmpty {
            RecognizedTextFeedbackView(result: rec)
        } else if let err = controller.recognitionError {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(STTheme.Colors.missOrange)
                Text(err)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(STTheme.Colors.missOrange)
            }
        }
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack(spacing: 10) {
            Button {
                controller.clearHandwriting()
            } label: {
                Label("Clear", systemImage: "eraser.line.dashed")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(STTheme.Colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 10, opacity: 0.10)
            }
            .disabled(controller.isDemoMode || controller.handwritingDrawing.bounds.isEmpty)

            Spacer()

            Button {
                onDrop()
            } label: {
                HStack(spacing: 5) {
                    if controller.isRecognizing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(STTheme.Colors.cosmicDeep)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Recognize & Drop")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(STTheme.Colors.cosmicDeep)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(STTheme.Colors.accentCyan)
                )
                .glow(STTheme.Colors.accentCyan, radius: 4)
            }
            .disabled(
                controller.isDemoMode
                || controller.isRecognizing
                || controller.handwritingDrawing.bounds.isEmpty
            )
        }
    }
}
