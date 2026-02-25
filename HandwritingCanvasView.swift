import SwiftUI
import PencilKit

/// PencilKit 手書き入力キャンバス。
/// 角丸・背景は UIKit 側で設定し、SwiftUI の clipShape を使わない。
/// これにより PKCanvasView の内部描画レイヤが確実に表示される。
struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.allowsFingerDrawing = true
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvas.isScrollEnabled = false
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        canvas.isMultipleTouchEnabled = true
        canvas.isUserInteractionEnabled = true
        canvas.layer.cornerRadius = 14
        canvas.layer.masksToBounds = true
        canvas.overrideUserInterfaceStyle = .light
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        guard !context.coordinator.isUpdating else { return }
        if uiView.drawing.dataRepresentation() != drawing.dataRepresentation() {
            uiView.drawing = drawing
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

// MARK: - Handwriting Input Panel

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
        HandwritingCanvasView(drawing: $controller.handwritingDrawing)
            .disabled(controller.isDemoMode)
            .frame(height: 120)
            .overlay(alignment: .center) {
                if controller.handwritingDrawing.bounds.isEmpty && !controller.isDemoMode {
                    Text("Write a word here")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray.opacity(0.35))
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .allowsHitTesting(false)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(canvasBorderColor, lineWidth: 1.5)
                    .allowsHitTesting(false)
            )
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
