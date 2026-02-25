import SwiftUI
import PencilKit

/// PencilKit ベースの手書き入力キャンバス。
/// Apple Pencil と指の両方に対応。白背景・黒線で Vision 認識精度を最大化。
struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var canvasSize: CGSize = CGSize(width: 400, height: 120)

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvas.contentSize = canvasSize
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
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
            HandwritingCanvasView(
                drawing: $controller.handwritingDrawing,
                canvasSize: CGSize(width: 340, height: 120)
            )
            .disabled(controller.isDemoMode)

            if controller.handwritingDrawing.bounds.isEmpty && !controller.isDemoMode {
                Text("Write a word here")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.gray.opacity(0.4))
                    .allowsHitTesting(false)
            }

            baselineGuide
        }
        .frame(height: 120)
        .background(Color.white)
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
