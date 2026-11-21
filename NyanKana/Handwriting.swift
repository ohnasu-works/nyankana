import SwiftUI
import UIKit
import PencilKit
import Vision

/// A writing pad for Apple Pencil or a finger. What you write is read on the device (Vision) a moment
/// after each stroke, and shown above the pad so you can see how it was read before answering.
struct HandwritingPad: View {
    var height: CGFloat
    /// called every time the reading changes
    var onRead: (String) -> Void = { _ in }
    /// the "answer" button; nil hides it (the screen has its own button)
    var onSubmit: ((String) -> Void)?

    @State private var canvas = PKCanvasView()
    @State private var read = ""
    @State private var token = 0
    @State private var busy = false
    @State private var erasing = false

    var body: some View {
        VStack(spacing: 6.s) {
            HStack(spacing: 8.s) {
                Image(systemName: "pencil.tip").font(.system(size: 14.s, weight: .black)).foregroundStyle(Color.ink.opacity(0.5))
                Text(read.isEmpty ? jp(T("ここに|英語を|書いてね", "여기에 영어를 써 봐", "在這裡寫英文")) : read)
                    .font(read.isEmpty ? .ui(13.s, bold: false) : .en(20.s))
                    .foregroundStyle(read.isEmpty ? Color.ink.opacity(0.45) : Color.ink)
                    .lineLimit(2).minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                if busy { ProgressView().scaleEffect(0.7) }
                // pen / eraser: rub out just one letter, then write it again
                padButton(erasing ? "pencil.tip" : "eraser.fill", on: erasing) {
                    erasing.toggle()
                    canvas.tool = erasing ? PKEraserTool(.vector) : PKInkingTool(.pen, color: .black, width: 5)
                }
                padButton("arrow.uturn.backward") { canvas.undoManager?.undo(); changed() }
                padButton("trash") { clear() }
            }
            ZStack {
                RoundedRectangle(cornerRadius: 14.s).fill(Color.white)
                // writing guide: a base line and a middle line, like an English notebook
                GeometryReader { g in
                    Path { p in
                        p.move(to: .init(x: 14, y: g.size.height * 0.68)); p.addLine(to: .init(x: g.size.width - 14, y: g.size.height * 0.68))
                    }.stroke(Color.sky.opacity(0.55), lineWidth: 2)
                    Path { p in
                        p.move(to: .init(x: 14, y: g.size.height * 0.4)); p.addLine(to: .init(x: g.size.width - 14, y: g.size.height * 0.4))
                    }.stroke(Color.sky.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                }
                CanvasHost(canvas: canvas, changed: changed)
            }
            .frame(height: height)
            .overlay(RoundedRectangle(cornerRadius: 14.s).stroke(Color.ink, lineWidth: 2.5))
            .clipShape(RoundedRectangle(cornerRadius: 14.s))
            if let onSubmit {
                PopButton(title: T("これで答える", "이걸로 답하기", "用這個作答"), color: .mint, height: 46) {
                    guard !read.isEmpty else { return }
                    onSubmit(read)
                    clear()
                }
            }
        }
    }

    private func padButton(_ icon: String, on: Bool = false, _ a: @escaping () -> Void) -> some View {
        Button { AudioManager.shared.se(.tap, rate: 1.4, volume: 0.4); a() } label: {
            Image(systemName: icon).font(.system(size: 15.s, weight: .bold)).foregroundStyle(on ? Color.white : Color.ink)
                .frame(width: 38.s, height: 32.s)
                .background(RoundedRectangle(cornerRadius: 9).fill(on ? Color.popDeep : Color.white).overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }

    private func clear() {
        canvas.drawing = PKDrawing()
        erasing = false
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        read = ""; onRead("")
    }

    private func changed() {
        token += 1
        let t = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { if t == token { recognize() } }
    }

    private func recognize() {
        let d = canvas.drawing
        guard !d.strokes.isEmpty else { read = ""; onRead(""); return }
        let box = d.bounds.insetBy(dx: -24, dy: -24)
        // dark ink on white, whatever the system appearance is
        let ink = UITraitCollection(userInterfaceStyle: .light)
        var strokesImage = UIImage()
        ink.performAsCurrent { strokesImage = d.image(from: box, scale: 2) }
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
        let img = UIGraphicsImageRenderer(size: strokesImage.size.applying(.init(scaleX: 2, y: 2)), format: fmt).image { c in
            UIColor.white.setFill(); c.fill(CGRect(origin: .zero, size: strokesImage.size.applying(.init(scaleX: 2, y: 2))))
            strokesImage.draw(in: CGRect(origin: .zero, size: strokesImage.size.applying(.init(scaleX: 2, y: 2))))
        }
        guard let cg = img.cgImage else { return }
        busy = true
        let t = token
        Task.detached(priority: .userInitiated) {
            let text = HandwritingPad.readText(cg)
            await MainActor.run {
                busy = false
                guard t == token else { return }
                read = text; onRead(text)
            }
        }
    }

    nonisolated static func readText(_ cg: CGImage) -> String {
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.recognitionLanguages = ["en-US"]
        req.usesLanguageCorrection = false        // read what was written, typos included
        try? VNImageRequestHandler(cgImage: cg).perform([req])
        // lines top to bottom
        let lines = (req.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        return lines.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

/// PencilKit canvas: Apple Pencil and fingers both write.
private struct CanvasHost: UIViewRepresentable {
    let canvas: PKCanvasView
    var changed: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.delegate = context.coordinator
        return canvas
    }
    func updateUIView(_ v: PKCanvasView, context: Context) { context.coordinator.changed = changed }
    func makeCoordinator() -> Coord { Coord(changed: changed) }

    final class Coord: NSObject, PKCanvasViewDelegate {
        var changed: () -> Void
        init(changed: @escaping () -> Void) { self.changed = changed }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) { changed() }
    }
}
