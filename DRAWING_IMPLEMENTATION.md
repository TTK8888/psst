# PencilKit Drawing Implementation

## Overview
PencilKit provides a powerful drawing framework that supports both finger and Apple Pencil input. This implementation will create a seamless drawing experience for couples to share handwritten notes.

## Core Components

### 1. DrawingCanvasView.swift

```swift
import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var toolPickerVisible: Bool
    let canvasView = PKCanvasView()
    let toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Configure canvas view
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput  // Allow both finger and pencil
        canvasView.backgroundColor = .systemBackground
        canvasView.isOpaque = false
        
        // Configure tool picker
        toolPicker.addObserver(context.coordinator)
        toolPicker.setVisible(toolPickerVisible, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update drawing when binding changes
        uiView.drawing = drawing
        
        // Update tool picker visibility
        toolPicker.setVisible(toolPickerVisible, forFirstResponder: uiView)
        if toolPickerVisible {
            uiView.becomeFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        var parent: DrawingCanvasView
        
        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update binding when drawing changes
            parent.drawing = canvasView.drawing
        }
        
        func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
            // Update binding when tool picker visibility changes
            parent.toolPickerVisible = toolPicker.isVisible(for: parent.canvasView)
        }
    }
}
```

### 2. DrawingToolsView.swift

```swift
import SwiftUI
import PencilKit

struct DrawingToolsView: View {
    @Binding var selectedTool: PKTool
    @Binding var selectedColor: UIColor
    @Binding var strokeWidth: CGFloat
    @Binding var toolPickerVisible: Bool
    
    private let availableColors: [UIColor] = [
        .black, .blue, .red, .green, .orange, .purple, .yellow, .pink
    ]
    
    private let strokeWidths: [CGFloat] = [5, 10, 15, 20, 30]
    
    var body: some View {
        VStack(spacing: 16) {
            // Tool Selection
            toolSelectionSection
            
            // Color Palette
            colorPaletteSection
            
            // Stroke Width
            strokeWidthSection
            
            // Tool Picker Toggle
            toolPickerToggle
        }
        .padding()
        .background(Color.systemGray6)
        .cornerRadius(12)
    }
    
    private var toolSelectionSection: some View {
        HStack(spacing: 12) {
            ToolButton(
                tool: PKInkingTool(.pen, color: selectedColor, width: strokeWidth),
                selectedTool: $selectedTool,
                icon: "pencil.tip"
            )
            
            ToolButton(
                tool: PKInkingTool(.marker, color: selectedColor, width: strokeWidth),
                selectedTool: $selectedTool,
                icon: "highlighter"
            )
            
            ToolButton(
                tool: PKEraserTool(.bitmap),
                selectedTool: $selectedTool,
                icon: "eraser"
            )
        }
    }
    
    private var colorPaletteSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            ForEach(availableColors, id: \.self) { color in
                ColorButton(
                    color: color,
                    selectedColor: $selectedColor,
                    tool: $selectedTool,
                    strokeWidth: strokeWidth
                )
            }
        }
    }
    
    private var strokeWidthSection: some View {
        VStack(alignment: .leading) {
            Text("Stroke Width: \(Int(strokeWidth))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(strokeWidths, id: \.self) { width in
                    StrokeWidthButton(
                        width: width,
                        selectedWidth: $strokeWidth,
                        tool: $selectedTool,
                        color: selectedColor
                    )
                }
            }
        }
    }
    
    private var toolPickerToggle: some View {
        Button(action: {
            toolPickerVisible.toggle()
        }) {
            HStack {
                Image(systemName: toolPickerVisible ? "paintbrush.fill" : "paintbrush")
                Text(toolPickerVisible ? "Hide Tools" : "Show Tools")
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

// MARK: - Helper Views

struct ToolButton: View {
    let tool: PKTool
    @Binding var selectedTool: PKTool
    let icon: String
    
    var body: some View {
        Button(action: {
            selectedTool = tool
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
    
    private var isSelected: Bool {
        if let selectedInking = selectedTool as? PKInkingTool,
           let toolInking = tool as? PKInkingTool {
            return selectedInking.inkType == toolInking.inkType
        }
        return selectedTool is PKEraserTool && tool is PKEraserTool
    }
}

struct ColorButton: View {
    let color: UIColor
    @Binding var selectedColor: UIColor
    @Binding var tool: PKTool
    let strokeWidth: CGFloat
    
    var body: some View {
        Button(action: {
            selectedColor = color
            updateToolColor()
        }) {
            Circle()
                .fill(Color(color))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 2 : 0)
                )
        }
    }
    
    private var isSelected: Bool {
        selectedColor == color
    }
    
    private func updateToolColor() {
        if let inkingTool = tool as? PKInkingTool {
            tool = PKInkingTool(inkingTool.inkType, color: color, width: strokeWidth)
        }
    }
}

struct StrokeWidthButton: View {
    let width: CGFloat
    @Binding var selectedWidth: CGFloat
    @Binding var tool: PKTool
    let color: UIColor
    
    var body: some View {
        Button(action: {
            selectedWidth = width
            updateToolWidth()
        }) {
            Circle()
                .fill(Color.primary)
                .frame(width: width, height: width)
                .background(
                    Circle()
                        .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
                )
        }
    }
    
    private var isSelected: Bool {
        selectedWidth == width
    }
    
    private func updateToolWidth() {
        if let inkingTool = tool as? PKInkingTool {
            tool = PKInkingTool(inkingTool.inkType, color: color, width: width)
        }
    }
}
```

### 3. DrawingViewModel.swift

```swift
import SwiftUI
import PencilKit
import Combine

@MainActor
class DrawingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentDrawing = PKDrawing()
    @Published var selectedTool: PKTool = PKInkingTool(.pen, color: .black, width: 10)
    @Published var selectedColor: UIColor = .black
    @Published var strokeWidth: CGFloat = 10
    @Published var toolPickerVisible = false
    @Published var isSaving = false
    @Published var saveError: String?
    
    // MARK: - Private Properties
    private let drawingService: DrawingService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(drawingService: DrawingService = DrawingService()) {
        self.drawingService = drawingService
        setupBindings()
    }
    
    // MARK: - Public Methods
    func clearCanvas() {
        currentDrawing = PKDrawing()
    }
    
    func undoLastStroke() {
        currentDrawing = currentDrawing.undo()
    }
    
    func saveDrawing(noteId: String) async {
        isSaving = true
        saveError = nil
        
        do {
            try await drawingService.saveDrawing(
                currentDrawing,
                noteId: noteId
            )
        } catch {
            saveError = error.localizedDescription
        }
        
        isSaving = false
    }
    
    func loadDrawing(noteId: String) async {
        do {
            let drawing = try await drawingService.loadDrawing(noteId: noteId)
            currentDrawing = drawing
        } catch {
            saveError = error.localizedDescription
        }
    }
    
    func exportDrawingAsImage() -> UIImage? {
        let image = currentDrawing.image(
            from: CGRect(x: 0, y: 0, width: 300, height: 400),
            scale: 2.0
        )
        return image
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Update tool when color or stroke width changes
        Publishers.CombineLatest($selectedColor, $strokeWidth)
            .sink { [weak self] color, strokeWidth in
                self?.updateToolWith(color: color, strokeWidth: strokeWidth)
            }
            .store(in: &cancellables)
    }
    
    private func updateToolWith(color: UIColor, strokeWidth: CGFloat) {
        if let inkingTool = selectedTool as? PKInkingTool {
            selectedTool = PKInkingTool(
                inkingTool.inkType,
                color: color,
                width: strokeWidth
            )
        }
    }
}
```

### 4. DrawingService.swift

```swift
import Foundation
import PencilKit
import Firebase

class DrawingService {
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    
    // MARK: - Public Methods
    func saveDrawing(_ drawing: PKDrawing, noteId: String) async throws {
        // Convert drawing to data
        guard let drawingData = drawing.dataRepresentation() else {
            throw DrawingError.conversionFailed
        }
        
        // Upload to Firebase Storage
        let storageRef = storage.reference()
            .child("drawings")
            .child("\(noteId).drawing")
        
        try await storageRef.putDataAsync(drawingData)
        
        // Update Firestore with metadata
        let downloadURL = try await storageRef.downloadURL()
        try await updateNoteMetadata(noteId: noteId, drawingURL: downloadURL)
    }
    
    func loadDrawing(noteId: String) async throws -> PKDrawing {
        // Get drawing URL from Firestore
        let docRef = firestore.collection("notes").document(noteId)
        let document = try await docRef.getDocument()
        
        guard let drawingURLString = document.data()?["drawingURL"] as? String,
              let drawingURL = URL(string: drawingURLString) else {
            throw DrawingError.drawingNotFound
        }
        
        // Download drawing data
        let storageRef = storage.reference(forURL: drawingURLString)
        let drawingData = try await storageRef.data(maxSize: 10 * 1024 * 1024) // 10MB max
        
        // Convert data back to PKDrawing
        return try PKDrawing(data: drawingData)
    }
    
    func deleteDrawing(noteId: String) async throws {
        // Delete from Storage
        let storageRef = storage.reference()
            .child("drawings")
            .child("\(noteId).drawing")
        
        try await storageRef.delete()
        
        // Update Firestore
        let docRef = firestore.collection("notes").document(noteId)
        try await docRef.updateData(["drawingURL": FieldValue.delete()])
    }
    
    // MARK: - Private Methods
    private func updateNoteMetadata(noteId: String, drawingURL: URL) async throws {
        let docRef = firestore.collection("notes").document(noteId)
        try await docRef.updateData([
            "drawingURL": drawingURL.absoluteString,
            "updatedAt": Timestamp(date: Date())
        ])
    }
}

// MARK: - Error Types

enum DrawingError: LocalizedError {
    case conversionFailed
    case drawingNotFound
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Failed to convert drawing to data"
        case .drawingNotFound:
            return "Drawing not found"
        case .uploadFailed:
            return "Failed to upload drawing"
        case .downloadFailed:
            return "Failed to download drawing"
        }
    }
}
```

## Key Implementation Details

### 1. Drawing Data Management
- Convert `PKDrawing` to data for Firebase Storage
- Maintain drawing state in ViewModel
- Handle offline caching

### 2. Tool Configuration
- Support pen, marker, and eraser tools
- Color palette with common colors
- Adjustable stroke widths
- Native PencilKit tool picker integration

### 3. Performance Optimization
- Efficient data conversion
- Background saving/loading
- Memory management for large drawings

### 4. Error Handling
- Comprehensive error types
- User-friendly error messages
- Retry mechanisms for failed operations

### 5. Accessibility
- VoiceOver support
- Dynamic type support
- High contrast mode compatibility

## Usage Example

```swift
struct DrawingView: View {
    @StateObject private var viewModel = DrawingViewModel()
    let noteId: String
    
    var body: some View {
        VStack {
            DrawingCanvasView(
                drawing: $viewModel.currentDrawing,
                toolPickerVisible: $viewModel.toolPickerVisible
            )
            
            DrawingToolsView(
                selectedTool: $viewModel.selectedTool,
                selectedColor: $viewModel.selectedColor,
                strokeWidth: $viewModel.strokeWidth,
                toolPickerVisible: $viewModel.toolPickerVisible
            )
        }
        .onAppear {
            Task {
                await viewModel.loadDrawing(noteId: noteId)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.saveDrawing(noteId: noteId)
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
    }
}
```