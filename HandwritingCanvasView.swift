import SwiftUI
import UIKit

// MARK: - UIKit Drawing View (finger-friendly, no PencilKit dependency)

/// 指で文字を書くための UIView。UIBezierPath + Core Graphics で描画。
/// PencilKit の SwiftUI 統合問題を回避するために自前実装。
final class FingerDrawView: UIView {
    var onDrawingChanged: ((UIImage?) -> Void)?

    private var path = UIBezierPath()
    private var cachedImage: UIImage?
    private let strokeColor: UIColor = .black
    private let strokeWidth: CGFloat = 4.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isMultipleTouchEnabled = false
        isUserInteractionEnabled = true
        layer.cornerRadius = 14
        layer.masksToBounds = true
        path.lineWidth = strokeWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        cachedImage?.draw(in: rect)
        strokeColor.setStroke()
        path.stroke()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        path.move(to: point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        path.addLine(to: point)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        flushPathToImage()
        onDrawingChanged?(snapshot())
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        flushPathToImage()
        onDrawingChanged?(snapshot())
    }

    func clear() {
        path.removeAllPoints()
        cachedImage = nil
        setNeedsDisplay()
        onDrawingChanged?(nil)
    }

    /// 現在の描画内容が空かどうか
    var isEmpty: Bool {
        cachedImage == nil && path.isEmpty
    }

    /// 白背景に黒線の画像を返す（Vision 認識用）
    func snapshot() -> UIImage? {
        guard !isEmpty else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            cachedImage?.draw(in: bounds)
            strokeColor.setStroke()
            path.stroke()
        }
    }

    private func flushPathToImage() {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        cachedImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            cachedImage?.draw(in: bounds)
            strokeColor.setStroke()
            path.stroke()
        }
        path.removeAllPoints()
    }
}

// MARK: - SwiftUI Wrapper

struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawingImage: UIImage?
    @Binding var hasStrokes: Bool
    var clearSignal: Bool

    func makeUIView(context: Context) -> FingerDrawView {
        let view = FingerDrawView()
        view.onDrawingChanged = { image in
            DispatchQueue.main.async {
                context.coordinator.updateDrawing(image: image)
            }
        }
        return view
    }

    func updateUIView(_ uiView: FingerDrawView, context: Context) {
        if clearSignal {
            uiView.clear()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingImage: $drawingImage, hasStrokes: $hasStrokes)
    }

    final class Coordinator {
        @Binding var drawingImage: UIImage?
        @Binding var hasStrokes: Bool

        init(drawingImage: Binding<UIImage?>, hasStrokes: Binding<Bool>) {
            _drawingImage = drawingImage
            _hasStrokes = hasStrokes
        }

        func updateDrawing(image: UIImage?) {
            drawingImage = image
            hasStrokes = image != nil
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

    private var canvasArea: some View {
        HandwritingCanvasView(
            drawingImage: $controller.handwritingImage,
            hasStrokes: $controller.hasHandwritingStrokes,
            clearSignal: controller.clearCanvasSignal
        )
        .frame(height: 120)
        .overlay(alignment: .center) {
            if !controller.hasHandwritingStrokes {
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
        if controller.isRecognizing { return STTheme.Colors.accentCyan }
        if !controller.hasHandwritingStrokes { return Color.gray.opacity(0.2) }
        return STTheme.Colors.accentCyan.opacity(0.5)
    }

    @ViewBuilder
    private var recognitionFeedback: some View {
        if controller.isRecognizing {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.8)
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
            .disabled(!controller.hasHandwritingStrokes)

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
                .background(Capsule().fill(STTheme.Colors.accentCyan))
                .glow(STTheme.Colors.accentCyan, radius: 4)
            }
            .disabled(
                controller.isRecognizing
                || !controller.hasHandwritingStrokes
            )
        }
    }
}
