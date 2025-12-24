# WidgetKit Implementation & Data Sharing

## Overview
The homescreen widget will provide quick access to the latest note from your partner, with the ability to view and potentially create simple drawings directly from the widget.

## Widget Architecture

### 1. Widget Extension Setup

#### LoveNotesWidget.swift

```swift
import WidgetKit
import SwiftUI

@main
struct LoveNotesWidget: Widget {
    let kind: String = "LoveNotesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoveNotesProvider()) { entry in
            LoveNotesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Love Notes")
        .description("See the latest note from your partner")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct LoveNotesWidget: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        LoveNotesWidget()
    }
}
```

### 2. Widget Provider

#### LoveNotesProvider.swift

```swift
import WidgetKit
import SwiftUI
import Intents

struct LoveNotesEntry: TimelineEntry {
    let date: Date
    let note: Note?
    let authorName: String?
    let drawingImage: UIImage?
    let isRefreshing: Bool
    
    static let placeholder = LoveNotesEntry(
        date: Date(),
        note: Note.placeholder,
        authorName: "Your Partner",
        drawingImage: nil,
        isRefreshing: false
    )
}

struct LoveNotesProvider: TimelineProvider {
    private let widgetService = WidgetService.shared
    
    func placeholder(in context: Context) -> LoveNotesEntry {
        return LoveNotesEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LoveNotesEntry) -> ()) {
        let entry = LoveNotesEntry.placeholder
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LoveNotesEntry>) -> ()) {
        Task {
            let entry = await loadLatestNote()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func loadLatestNote() async -> LoveNotesEntry {
        do {
            let latestNote = try await widgetService.getLatestNote()
            let authorName = try await widgetService.getAuthorName(for: latestNote.authorId)
            let drawingImage = try await widgetService.loadDrawingImage(noteId: latestNote.id)
            
            return LoveNotesEntry(
                date: Date(),
                note: latestNote,
                authorName: authorName,
                drawingImage: drawingImage,
                isRefreshing: false
            )
        } catch {
            print("Error loading latest note: \(error)")
            return LoveNotesEntry(
                date: Date(),
                note: nil,
                authorName: nil,
                drawingImage: nil,
                isRefreshing: false
            )
        }
    }
}
```

### 3. Widget Entry View

#### WidgetEntryView.swift

```swift
import SwiftUI
import WidgetKit

struct LoveNotesWidgetEntryView: View {
    var entry: LoveNotesEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                contentView
                
                Spacer(minLength: 8)
                
                // Footer
                footerView
            }
            .padding()
        }
        .background(Color.systemBackground)
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.pink)
                .font(.caption)
            
            Text("Love Note")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if entry.isRefreshing {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let note = entry.note {
            noteContentView(note)
        } else {
            emptyStateView
        }
    }
    
    @ViewBuilder
    private func noteContentView(_ note: Note) -> Void {
        VStack(alignment: .leading, spacing: 8) {
            // Author name
            if let authorName = entry.authorName {
                Text("From \(authorName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Drawing or text content
            if let drawingImage = entry.drawingImage {
                drawingView(drawingImage)
            } else if !note.content.isEmpty {
                textView(note.content)
            }
            
            // Timestamp
            Text(formatDate(note.createdAt))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.text.square")
                .font(.largeTitle)
                .foregroundColor(.pink.opacity(0.5))
            
            Text("No notes yet")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Open the app to leave a note")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func drawingView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: drawingMaxHeight)
            .cornerRadius(8)
            .shadow(radius: 2)
    }
    
    @ViewBuilder
    private func textView(_ content: String) -> some View {
        Text(content)
            .font(.body)
            .foregroundColor(.primary)
            .lineLimit(widgetFamily == .systemSmall ? 3 : 5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var footerView: some View {
        HStack {
            Spacer()
            
            Link(destination: URL(string: "lovenotes://app")!) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Note")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.pink)
                .cornerRadius(12)
            }
        }
    }
    
    private var drawingMaxHeight: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 80
        case .systemMedium:
            return 120
        case .systemLarge:
            return 160
        default:
            return 100
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Widget Preview

#Preview(as: .systemSmall) {
    LoveNotesWidget()
} timeline: {
    LoveNotesEntry.placeholder
}

#Preview(as: .systemMedium) {
    LoveNotesWidget()
} timeline: {
    LoveNotesEntry.placeholder
}

#Preview(as: .systemLarge) {
    LoveNotesWidget()
} timeline: {
    LoveNotesEntry.placeholder
}
```

### 4. Widget Service

#### WidgetService.swift

```swift
import Foundation
import UIKit
import Firebase
import FirebaseFirestore

class WidgetService: ObservableObject {
    static let shared = WidgetService()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.lovenotes.widget")
    private let firebaseService = FirebaseService.shared
    
    // UserDefaults Keys
    private let latestNoteKey = "latestNote"
    private let authorNameKey = "authorName"
    private let lastUpdateKey = "lastUpdate"
    
    // MARK: - Public Methods
    func updateWidgetData(with note: Note, authorName: String) async {
        do {
            // Save note data to UserDefaults
            try saveNoteToUserDefaults(note, authorName: authorName)
            
            // Save drawing image if exists
            if note.drawingURL != nil {
                try await saveDrawingImageToUserDefaults(noteId: note.id)
            }
            
            // Update last update timestamp
            userDefaults?.set(Date(), forKey: lastUpdateKey)
            
            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("Error updating widget data: \(error)")
        }
    }
    
    func getLatestNote() async throws -> Note {
        guard let noteData = userDefaults?.data(forKey: latestNoteKey) else {
            throw WidgetError.noNoteFound
        }
        
        return try JSONDecoder().decode(Note.self, from: noteData)
    }
    
    func getAuthorName(for userId: String) async throws -> String {
        // Try to get from cache first
        if let cachedName = userDefaults?.string(forKey: "authorName_\(userId)") {
            return cachedName
        }
        
        // Fetch from Firestore
        let docSnapshot = try await firebaseService.firestore
            .collection("users")
            .document(userId)
            .getDocument()
        
        guard let data = docSnapshot.data(),
              let displayName = data["displayName"] as? String else {
            throw WidgetError.authorNameNotFound
        }
        
        // Cache the name
        userDefaults?.set(displayName, forKey: "authorName_\(userId)")
        
        return displayName
    }
    
    func loadDrawingImage(noteId: String) async throws -> UIImage? {
        guard let imageData = userDefaults?.data(forKey: "drawingImage_\(noteId)") else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    func clearWidgetData() {
        userDefaults?.removeObject(forKey: latestNoteKey)
        userDefaults?.removeObject(forKey: authorNameKey)
        userDefaults?.removeObject(forKey: lastUpdateKey)
        
        // Clear all cached drawing images
        if let allKeys = userDefaults?.dictionaryRepresentation().keys {
            for key in allKeys {
                if key.hasPrefix("drawingImage_") {
                    userDefaults?.removeObject(forKey: key)
                }
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Private Methods
    private func saveNoteToUserDefaults(_ note: Note, authorName: String) throws {
        let noteData = try JSONEncoder().encode(note)
        userDefaults?.set(noteData, forKey: latestNoteKey)
        userDefaults?.set(authorName, forKey: authorNameKey)
    }
    
    private func saveDrawingImageToUserDefaults(noteId: String) async throws {
        // Download drawing data
        let drawingData = try await firebaseService.downloadDrawing(noteId: noteId)
        
        // Convert to UIImage and compress
        guard let image = UIImage(data: drawingData) else {
            throw WidgetError.imageConversionFailed
        }
        
        // Compress image for widget
        let compressedImageData = image.jpegData(compressionQuality: 0.7)
        
        // Save to UserDefaults
        userDefaults?.set(compressedImageData, forKey: "drawingImage_\(noteId)")
    }
}

// MARK: - Error Types
enum WidgetError: LocalizedError {
    case noNoteFound
    case authorNameNotFound
    case imageConversionFailed
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .noNoteFound:
            return "No note found in widget data"
        case .authorNameNotFound:
            return "Author name not found"
        case .imageConversionFailed:
            return "Failed to convert drawing to image"
        case .dataCorrupted:
            return "Widget data is corrupted"
        }
    }
}
```

### 5. App Groups Configuration

#### App Groups Setup

1. **Create App Group**
   - In Xcode, go to Project Settings → Signing & Capabilities
   - Click "+ Capability" and add "App Groups"
   - Create a new app group: `group.com.lovenotes.widget`

2. **Add to Both Targets**
   - Add the same app group to both main app and widget extension
   - Ensure both targets have the same group identifier

3. **Update Info.plist**
   - Add app group entitlements to both targets

#### Shared Constants

```swift
// AppConstants.swift
struct AppConstants {
    // App Groups
    static let appGroupIdentifier = "group.com.lovenotes.widget"
    
    // Widget Keys
    static let widgetLatestNoteKey = "latestNote"
    static let widgetAuthorNameKey = "authorName"
    static let widgetLastUpdateKey = "lastUpdate"
    static let widgetDrawingImagePrefix = "drawingImage_"
    
    // Deep Links
    static let appDeepLinkScheme = "lovenotes"
    static let appDeepLinkHost = "app"
    
    // Widget Refresh Intervals
    static let widgetRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
}
```

### 6. Widget Integration in Main App

#### WidgetManager.swift

```swift
import Foundation
import WidgetKit
import Combine

@MainActor
class WidgetManager: ObservableObject {
    static let shared = WidgetManager()
    
    private let widgetService = WidgetService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    func updateWidgetWithLatestNote() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Get couple ID
            let coupleId = try await FirebaseService.shared.getCoupleId(forUserId: userId)
            guard let coupleId = coupleId else { return }
            
            // Get latest note
            let notes = try await FirebaseService.shared.getNotesForCouple(coupleId: coupleId)
            guard let latestNote = notes.first else { return }
            
            // Get author name
            let authorName = try await widgetService.getAuthorName(for: latestNote.authorId)
            
            // Update widget
            await widgetService.updateWidgetData(with: latestNote, authorName: authorName)
            
        } catch {
            print("Error updating widget: \(error)")
        }
    }
    
    func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func refreshWidget(ofKind kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
    
    func clearWidgetData() {
        widgetService.clearWidgetData()
    }
    
    // MARK: - Widget Configuration
    func configureWidgetUpdates() {
        // Listen for note changes and update widget
        NotificationCenter.default.publisher(for: .noteDidCreate)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateWidgetWithLatestNote()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .noteDidUpdate)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateWidgetWithLatestNote()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let noteDidCreate = Notification.Name("noteDidCreate")
    static let noteDidUpdate = Notification.Name("noteDidUpdate")
    static let noteDidDelete = Notification.Name("noteDidDelete")
}
```

### 7. Interactive Widget Features

#### App Intents for Widget Interaction

```swift
import Intents
import IntentsUI

struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create New Note"
    
    @Parameter(title: "Message")
    var message: String
    
    func perform() async throws -> some IntentResult {
        // Open app with pre-filled message
        guard let url = URL(string: "lovenotes://create?message=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw AppIntentError.failedToCreateURL
        }
        
        await UIApplication.shared.open(url)
        return .result()
    }
}

struct ViewLatestNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "View Latest Note"
    
    func perform() async throws -> some IntentResult {
        // Open app to latest note
        guard let url = URL(string: "lovenotes://latest") else {
            throw AppIntentError.failedToCreateURL
        }
        
        await UIApplication.shared.open(url)
        return .result()
    }
}

enum AppIntentError: LocalizedError {
    case failedToCreateURL
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateURL:
            return "Failed to create app URL"
        }
    }
}
```

## Key Implementation Details

### 1. Data Sharing
- App Groups for UserDefaults sharing
- Efficient data serialization
- Image compression for widget constraints

### 2. Real-Time Updates
- Timeline-based widget updates
- Manual refresh triggers
- Background refresh considerations

### 3. Performance
- Lazy loading of drawing images
- Cached author names
- Optimized data structures

### 4. User Experience
- Multiple widget sizes support
- Graceful fallbacks for missing data
- Deep linking to main app

### 5. Error Handling
- Comprehensive error types
- Fallback to placeholder content
- Network resilience

## Usage Example

```swift
// In main app, when a new note is created
@MainActor
class NotesViewModel: ObservableObject {
    private let widgetManager = WidgetManager.shared
    
    func createNote(content: String) async {
        // Create note logic...
        
        // Update widget
        await widgetManager.updateWidgetWithLatestNote()
        
        // Post notification
        NotificationCenter.default.post(.init(name: .noteDidCreate))
    }
}
```

## Widget Limitations & Solutions

### 1. Memory Constraints
- **Problem**: Widgets have limited memory (50MB)
- **Solution**: Compress images, cache efficiently, use lazy loading

### 2. Network Restrictions
- **Problem**: Limited network access in widgets
- **Solution**: Use shared UserDefaults, pre-fetch data, background updates

### 3. Interaction Limitations
- **Problem**: Limited interactive capabilities
- **Solution**: Deep links, App Intents, smart tap targets

### 4. Refresh Frequency
- **Problem**: Limited refresh frequency
- **Solution**: Smart timeline updates, user-triggered refreshes