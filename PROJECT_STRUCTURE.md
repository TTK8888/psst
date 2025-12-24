# Project Structure

## Directory Layout

```
LoveNotes/
├── App/
│   ├── LoveNotesApp.swift
│   ├── ContentView.swift
│   └── AppDelegate.swift
├── Features/
│   ├── Drawing/
│   │   ├── Views/
│   │   │   ├── DrawingCanvasView.swift
│   │   │   ├── DrawingToolsView.swift
│   │   │   └── ColorPaletteView.swift
│   │   ├── ViewModels/
│   │   │   └── DrawingViewModel.swift
│   │   └── Models/
│   │       └── DrawingNote.swift
│   ├── Notes/
│   │   ├── Views/
│   │   │   ├── NotesListView.swift
│   │   │   ├── NoteDetailView.swift
│   │   │   └── NoteCellView.swift
│   │   ├── ViewModels/
│   │   │   └── NotesViewModel.swift
│   │   └── Models/
│   │       └── Note.swift
│   ├── Auth/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   ├── SignUpView.swift
│   │   │   └── PairingView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift
│   │   └── Models/
│   │       └── User.swift
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   └── ProfileView.swift
│       ├── ViewModels/
│       │   └── SettingsViewModel.swift
│       └── Models/
│           └── AppSettings.swift
├── Services/
│   ├── FirebaseService.swift
│   ├── DrawingService.swift
│   ├── AuthService.swift
│   ├── NotificationService.swift
│   └── WidgetService.swift
├── Widget/
│   ├── LoveNotesWidget.swift
│   ├── WidgetEntryView.swift
│   ├── WidgetProvider.swift
│   └── Info.plist
├── Shared/
│   ├── Models/
│   │   ├── Note.swift
│   │   ├── User.swift
│   │   ├── DrawingData.swift
│   │   └── AppConstants.swift
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   └── Data+Extensions.swift
│   └── Utilities/
│       ├── DateFormatter+Extensions.swift
│       ├── ImageProcessor.swift
│       └── StorageManager.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Info.plist
└── Tests/
    ├── UnitTests/
    └── UITests/
```

## Key Components

### App Layer
- **LoveNotesApp.swift**: Main app entry point
- **ContentView.swift**: Root view controller
- **AppDelegate.swift**: App lifecycle and Firebase setup

### Features Layer
Organized by feature with MVVM architecture:
- **Views**: SwiftUI views
- **ViewModels**: Business logic and state management
- **Models**: Data models specific to each feature

### Services Layer
- **FirebaseService**: Firebase integration
- **DrawingService**: Drawing data management
- **AuthService**: User authentication
- **NotificationService**: Push notifications
- **WidgetService**: Widget data management

### Widget Extension
- **LoveNotesWidget.swift**: Widget configuration
- **WidgetEntryView.swift**: Widget UI
- **WidgetProvider.swift**: Timeline provider

### Shared Layer
- **Models**: Core data models
- **Extensions**: Utility extensions
- **Utilities**: Helper classes

## Architecture Patterns

### MVVM (Model-View-ViewModel)
- Views observe ViewModels for state changes
- ViewModels handle business logic
- Models represent data structures

### Dependency Injection
- Services injected into ViewModels
- ViewModels injected into Views
- Testable and maintainable code

### Coordinator Pattern (Optional)
- Navigation flow management
- Deep linking support
- Feature separation