import SwiftUI
import PencilKit

/// iPad 画面下部で Apple Pencil / 指による手書き入力。
/// 白背景・黒線で Vision の認識精度を最大化（SSC 仕様準拠）。
struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var canvasSize: CGSize = CGSize(width: 400, height: 80)

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput  // Apple Pencil と指の両方
        canvas.backgroundColor = .white
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvas.contentSize = canvasSize
        canvas.isOpaque = false
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

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}

// MARK: - 描画を UIImage に変換（Vision 入力用）

extension HandwritingCanvasView {
    /// 現在の描画を白背景の画像として取得
    static func image(from drawing: PKDrawing, size: CGSize, scale: CGFloat = 2.0) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let img = drawing.image(from: rect, scale: scale)

        // 白背景に合成（Vision の認識精度向上）
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(rect)
            img.draw(in: rect)
        }
    }
}
