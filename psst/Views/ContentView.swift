import SwiftUI
import PencilKit
import WidgetKit

struct ContentView: View {
    @State private var canvas = PKCanvasView()
    @State private var selectedColor: Color = .black
    @State private var selectedTool: ToolType = .pen
    @State private var lineWidth: CGFloat = 5.0

    enum ToolType: String, CaseIterable {
        case pen = "Pen"
        case pencil = "Pencil"
        case marker = "Marker"
        case eraser = "Eraser"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // tool bar
            toolBar
            
            // Canvas
            CanvasView(canvas: $canvas)
                .background(Color.white)
            
            // bottom buttons
            HStack {
                Button(action: {
                    canvas.drawing = PKDrawing()
                }) {
                    Text("Clear")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: {
                    saveDrawing()
                }) {
                    Text("Save")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .init(horizontal: .center, vertical: .center))
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(10)
            }
            .background(Color.gray.opacity(0.01))
        }
    }
    
    var toolBar: some View {
        VStack(spacing: 10) {
            // tool selector
            HStack {
                ForEach(ToolType.allCases, id: \.self) { tool in
                    Button(action: {
                        selectedTool = tool
                        updateTool()
                    }) {
                        Text(tool.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTool == tool ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            HStack(spacing: 16) {
                // Color picker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .onChange(of: selectedColor) {
                        updateTool()
                    }
                // Line Width slider
                HStack {
                    Text("Size")
                        .font(.caption)
                    Slider(value: $lineWidth, in: 1...20, step: 1)
                        .frame(width: 120)
                        .onChange(of: lineWidth) {
                            updateTool()
                        }
                    Text("\(Int(lineWidth))")
                        .font(.caption)
                        .frame(width: 24)
                }
            }
        }
        .padding(10)
        .background(Color.white)
    }
    
    // Update tool
    func updateTool() {
        let uiColor = UIColor(selectedColor)
        
        switch selectedTool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: uiColor, width: lineWidth)
        case .pencil:
            canvas.tool = PKInkingTool(.pencil, color: uiColor, width: lineWidth)
        case .marker:
            canvas.tool = PKInkingTool(.marker, color: uiColor, width: lineWidth)
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        }
    }
    
    func saveDrawing() {
        let bounds = canvas.bounds
        let image = canvas.drawing.image(from: bounds, scale: 2.0)
        
        guard let data = image.pngData() else {
            print("Failed to convert image to PNG")
            return
        }
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.psst.shared"
        ) else {
            print("Failed to get container URL")
            return
        }
        
        let fileURL = containerURL.appendingPathComponent("note.png")
        
        do {
            try data.write(to: fileURL)
            print("Saved to: \(fileURL)")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to save \(fileURL): \(error)")
        }
    }
}

#Preview {
    ContentView()
}
