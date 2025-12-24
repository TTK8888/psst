# Data Models & Core Structures

## Overview
This document defines all the data models, enums, and core structures used throughout the LoveNotes app. These models follow Swift's Codable protocol for easy serialization with Firebase and local storage.

## Core Models

### 1. Note Model

```swift
import Foundation
import FirebaseFirestore

struct Note: Codable, Identifiable, Equatable {
    // MARK: - Properties
    let id: String
    let authorId: String
    let coupleId: String
    var content: String
    var drawingURL: String?
    let createdAt: Date
    var updatedAt: Date
    var isRead: Bool
    
    // MARK: - Computed Properties
    var hasDrawing: Bool {
        return drawingURL != nil && !drawingURL!.isEmpty
    }
    
    var isEmpty: Bool {
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasDrawing
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        authorId: String,
        coupleId: String,
        content: String = "",
        drawingURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.authorId = authorId
        self.coupleId = coupleId
        self.content = content
        self.drawingURL = drawingURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isRead = isRead
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case coupleId
        case content
        case drawingURL
        case createdAt
        case updatedAt
        case isRead
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        authorId = try container.decode(String.self, forKey: .authorId)
        coupleId = try container.decode(String.self, forKey: .coupleId)
        content = try container.decode(String.self, forKey: .content)
        drawingURL = try container.decodeIfPresent(String.self, forKey: .drawingURL)
        
        // Handle Firebase Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
        
        isRead = try container.decode(Bool.self, forKey: .isRead)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(authorId, forKey: .authorId)
        try container.encode(coupleId, forKey: .coupleId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(drawingURL, forKey: .drawingURL)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
        try container.encode(isRead, forKey: .isRead)
    }
    
    // MARK: - Equatable
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Mock Data
    static let placeholder = Note(
        authorId: "placeholder",
        coupleId: "placeholder",
        content: "I love you! ❤️",
        drawingURL: nil,
        createdAt: Date(),
        updatedAt: Date(),
        isRead: false
    )
}
```

### 2. User Model

```swift
import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    // MARK: - Properties
    let id: String
    var email: String
    var displayName: String?
    var photoURL: String?
    var partnerId: String?
    let createdAt: Date
    var lastActiveAt: Date
    
    // MARK: - Computed Properties
    var hasPartner: Bool {
        return partnerId != nil && !partnerId!.isEmpty
    }
    
    var initials: String {
        let components = displayName?.components(separatedBy: " ") ?? []
        return components.map { String($0.prefix(1)) }.joined()
    }
    
    // MARK: - Initialization
    init(
        id: String,
        email: String,
        displayName: String? = nil,
        photoURL: String? = nil,
        partnerId: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.partnerId = partnerId
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case photoURL
        case partnerId
        case createdAt
        case lastActiveAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        partnerId = try container.decodeIfPresent(String.self, forKey: .partnerId)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastActiveAt) {
            lastActiveAt = timestamp.dateValue()
        } else {
            lastActiveAt = try container.decode(Date.self, forKey: .lastActiveAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encodeIfPresent(partnerId, forKey: .partnerId)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: lastActiveAt), forKey: .lastActiveAt)
    }
}
```

### 3. Couple Model

```swift
import Foundation
import FirebaseFirestore

struct Couple: Codable, Identifiable {
    // MARK: - Properties
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date
    var status: CoupleStatus
    var invitationCode: String?
    
    // MARK: - Computed Properties
    var isActive: Bool {
        return status == .active
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        user1Id: String,
        user2Id: String,
        createdAt: Date = Date(),
        status: CoupleStatus = .active,
        invitationCode: String? = nil
    ) {
        self.id = id
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.createdAt = createdAt
        self.status = status
        self.invitationCode = invitationCode
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id
        case user2Id
        case createdAt
        case status
        case invitationCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        user1Id = try container.decode(String.self, forKey: .user1Id)
        user2Id = try container.decode(String.self, forKey: .user2Id)
        status = try container.decode(CoupleStatus.self, forKey: .status)
        invitationCode = try container.decodeIfPresent(String.self, forKey: .invitationCode)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(user1Id, forKey: .user1Id)
        try container.encode(user2Id, forKey: .user2Id)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(invitationCode, forKey: .invitationCode)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
```

## Enums & Supporting Types

### 1. Couple Status

```swift
enum CoupleStatus: String, Codable, CaseIterable {
    case active = "active"
    case pending = "pending"
    case dissolved = "dissolved"
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .pending:
            return "Pending"
        case .dissolved:
            return "Dissolved"
        }
    }
}
```

### 2. Drawing Tool Types

```swift
import PencilKit

enum DrawingTool: String, CaseIterable {
    case pen = "pen"
    case pencil = "pencil"
    case marker = "marker"
    case eraser = "eraser"
    
    var displayName: String {
        switch self {
        case .pen:
            return "Pen"
        case .pencil:
            return "Pencil"
        case .marker:
            return "Marker"
        case .eraser:
            return "Eraser"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pen:
            return "pencil.tip"
        case .pencil:
            return "pencil"
        case .marker:
            return "highlighter"
        case .eraser:
            return "eraser"
        }
    }
    
    var pencilKitTool: PKTool {
        switch self {
        case .pen:
            return PKInkingTool(.pen, color: .black, width: 10)
        case .pencil:
            return PKInkingTool(.pencil, color: .black, width: 10)
        case .marker:
            return PKInkingTool(.marker, color: .black, width: 20)
        case .eraser:
            return PKEraserTool(.bitmap)
        }
    }
}
```

### 3. App Settings

```swift
struct AppSettings: Codable {
    // MARK: - Properties
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var hapticFeedbackEnabled: Bool
    var darkModeEnabled: Bool
    var autoSaveEnabled: Bool
    var widgetEnabled: Bool
    
    // MARK: - Drawing Settings
    var defaultTool: DrawingTool
    var defaultColor: String // Hex color
    var defaultStrokeWidth: CGFloat
    
    // MARK: - Privacy Settings
    var analyticsEnabled: Bool
    var crashReportingEnabled: Bool
    
    // MARK: - Initialization
    init(
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        hapticFeedbackEnabled: Bool = true,
        darkModeEnabled: Bool = false,
        autoSaveEnabled: Bool = true,
        widgetEnabled: Bool = true,
        defaultTool: DrawingTool = .pen,
        defaultColor: String = "#000000",
        defaultStrokeWidth: CGFloat = 10,
        analyticsEnabled: Bool = true,
        crashReportingEnabled: Bool = true
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.darkModeEnabled = darkModeEnabled
        self.autoSaveEnabled = autoSaveEnabled
        self.widgetEnabled = widgetEnabled
        self.defaultTool = defaultTool
        self.defaultColor = defaultColor
        self.defaultStrokeWidth = defaultStrokeWidth
        self.analyticsEnabled = analyticsEnabled
        self.crashReportingEnabled = crashReportingEnabled
    }
    
    // MARK: - Default Settings
    static let `default` = AppSettings()
}
```

### 4. Error Types

```swift
enum AppError: LocalizedError, Equatable {
    // Authentication Errors
    case notAuthenticated
    case authenticationFailed(String)
    case userNotFound
    case emailAlreadyInUse
    
    // Couple Errors
    case coupleNotFound
    case alreadyPaired
    case invitationInvalid
    case invitationExpired
    
    // Note Errors
    case noteNotFound
    case noteCreationFailed
    case noteUpdateFailed
    case noteDeleteFailed
    
    // Drawing Errors
    case drawingNotFound
    case drawingUploadFailed
    case drawingDownloadFailed
    case drawingCorrupted
    
    // Network Errors
    case networkUnavailable
    case serverError(String)
    case timeout
    
    // Storage Errors
    case storageQuotaExceeded
    case storagePermissionDenied
    
    // Widget Errors
    case widgetNotConfigured
    case widgetDataCorrupted
    
    var errorDescription: String? {
        switch self {
        // Authentication
        case .notAuthenticated:
            return "Please sign in to continue"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .userNotFound:
            return "User account not found"
        case .emailAlreadyInUse:
            return "Email address is already in use"
            
        // Couple
        case .coupleNotFound:
            return "No couple relationship found"
        case .alreadyPaired:
            return "You are already paired with someone"
        case .invitationInvalid:
            return "Invitation code is invalid"
        case .invitationExpired:
            return "Invitation code has expired"
            
        // Note
        case .noteNotFound:
            return "Note not found"
        case .noteCreationFailed:
            return "Failed to create note"
        case .noteUpdateFailed:
            return "Failed to update note"
        case .noteDeleteFailed:
            return "Failed to delete note"
            
        // Drawing
        case .drawingNotFound:
            return "Drawing not found"
        case .drawingUploadFailed:
            return "Failed to upload drawing"
        case .drawingDownloadFailed:
            return "Failed to download drawing"
        case .drawingCorrupted:
            return "Drawing data is corrupted"
            
        // Network
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .serverError(let message):
            return "Server error: \(message)"
        case .timeout:
            return "Request timed out"
            
        // Storage
        case .storageQuotaExceeded:
            return "Storage quota exceeded"
        case .storagePermissionDenied:
            return "Storage permission denied"
            
        // Widget
        case .widgetNotConfigured:
            return "Widget is not configured"
        case .widgetDataCorrupted:
            return "Widget data is corrupted"
        }
    }
    
    var failureReason: String? {
        return errorDescription
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .authenticationFailed:
            return "Please try signing in again"
        case .serverError:
            return "Please try again later"
        case .timeout:
            return "Please check your connection and try again"
        default:
            return "Please try again"
        }
    }
}
```

## Utility Models

### 1. Drawing Data Wrapper

```swift
struct DrawingData: Codable {
    let noteId: String
    let data: Data
    let format: DrawingFormat
    let createdAt: Date
    
    enum DrawingFormat: String, Codable {
        case pencilKit = "pencilkit"
        case png = "png"
        case jpeg = "jpeg"
    }
}
```

### 2. Notification Payload

```swift
struct NotificationPayload: Codable {
    let type: NotificationType
    let noteId: String?
    let title: String
    let body: String
    let sound: String?
    
    enum NotificationType: String, Codable {
        case newNote = "new_note"
        case noteUpdated = "note_updated"
        case partnerRequest = "partner_request"
        case partnerAccepted = "partner_accepted"
    }
}
```

### 3. Analytics Event

```swift
struct AnalyticsEvent: Codable {
    let name: String
    let parameters: [String: Any]?
    let timestamp: Date
    
    init(name: String, parameters: [String: Any]? = nil, timestamp: Date = Date()) {
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
    }
    
    // Common event types
    static let noteCreated = AnalyticsEvent(name: "note_created")
    static let noteViewed = AnalyticsEvent(name: "note_viewed")
    static let drawingCreated = AnalyticsEvent(name: "drawing_created")
    static let userSignedIn = AnalyticsEvent(name: "user_signed_in")
    static let couplePaired = AnalyticsEvent(name: "couple_paired")
    static let widgetTapped = AnalyticsEvent(name: "widget_tapped")
}
```

## Constants & Configuration

### 1. App Constants

```swift
struct AppConstants {
    // MARK: - App Information
    static let appName = "LoveNotes"
    static let appVersion = "1.0.0"
    static let bundleIdentifier = "com.lovenotes.app"
    
    // MARK: - Firebase Collections
    static let usersCollection = "users"
    static let notesCollection = "notes"
    static let couplesCollection = "couples"
    
    // MARK: - Storage Paths
    static let drawingsPath = "drawings"
    static let profilePicturesPath = "profile-pictures"
    
    // MARK: - App Groups
    static let appGroupIdentifier = "group.com.lovenotes.widget"
    
    // MARK: - Widget Configuration
    static let widgetRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    static let maxWidgetImageSize = 500 // pixels
    
    // MARK: - Drawing Configuration
    static let maxDrawingSize = 10 * 1024 * 1024 // 10MB
    static let defaultStrokeWidth: CGFloat = 10
    static let maxStrokeWidth: CGFloat = 50
    
    // MARK: - UI Configuration
    static let animationDuration: Double = 0.3
    static let hapticFeedbackIntensity: CGFloat = 0.7
    
    // MARK: - Pagination
    static let notesPageSize = 20
    static let maxNotesPerPage = 50
}
```

### 2. Color Palette

```swift
struct AppColors {
    // MARK: - Brand Colors
    static let primary = Color(hex: "#FF69B4") // Hot Pink
    static let secondary = Color(hex: "#9370DB") // Medium Purple
    static let accent = Color(hex: "#FFB6C1") // Light Pink
    
    // MARK: - Drawing Colors
    static let drawingColors: [Color] = [
        .black,
        .white,
        .red,
        .blue,
        .green,
        .yellow,
        .orange,
        .purple,
        .pink,
        .brown,
        .gray
    ]
    
    // MARK: - System Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
}
```

## Usage Examples

### Creating a New Note

```swift
let newNote = Note(
    authorId: currentUser.id,
    coupleId: couple.id,
    content: "I love you!",
    drawingURL: nil
)
```

### Updating User Profile

```swift
var updatedUser = currentUser
updatedUser.displayName = "John Doe"
updatedUser.photoURL = "https://example.com/avatar.jpg"
```

### Handling Errors

```swift
do {
    try await notesService.createNote(content: "Hello!")
} catch let error as AppError {
    showAlert(title: "Error", message: error.localizedDescription)
}
```

### Firebase Document Mapping

```swift
// Convert Note to Firestore document
func noteToDocument(_ note: Note) -> [String: Any] {
    return [
        "id": note.id,
        "authorId": note.authorId,
        "coupleId": note.coupleId,
        "content": note.content,
        "drawingURL": note.drawingURL as Any,
        "createdAt": Timestamp(date: note.createdAt),
        "updatedAt": Timestamp(date: note.updatedAt),
        "isRead": note.isRead
    ]
}
```

This comprehensive data model structure provides a solid foundation for the LoveNotes app, ensuring type safety, proper serialization, and maintainability throughout the development process.