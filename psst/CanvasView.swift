//
//  CanvasView.swift
//  psst
//
//  Created by Taraaf Khalidi on 28/12/2025.
//

import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
    }
}
