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
        case Eraser = "Eraser"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CanvasView(canvas: $canvas)
                .background(Color.white)
            
        HStack{
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
