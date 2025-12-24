# Setup Instructions & Quick Start

## Prerequisites

Before you begin building the LoveNotes app, ensure you have the following:

### Required Tools
- **Mac with Apple Silicon** (M1/M2/M3) - Recommended for optimal performance
- **Cursor IDE** - Your primary code editor
- **Xcode 15.0+** - Required for building, running, and managing iOS projects (installed but used minimally)
- **iOS 17.0+** - Minimum deployment target
- **Apple Developer Account** ($99/year) - For testing and App Store submission

### Optional Tools
- **Physical iOS devices** - iPhone and iPad for testing
- **Apple Pencil** - For testing drawing features
- **Firebase account** - Free tier available

---

## Project Setup

### Step 1: Create New Xcode Project

**Note**: While you'll use Cursor for editing, you still need Xcode to create the initial project structure.

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose **iOS** → **App**
4. Fill in project details:
   - **Product Name**: `LoveNotes`
   - **Bundle Identifier**: `com.yourname.lovenotes`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None` (we'll add Core Data later)
5. Save the project to your desired location
6. Close Xcode and open the project folder in Cursor

### Step 2: Configure Project Structure

1. In Cursor, create the following folders using the file explorer:
   ```
   LoveNotes/
   ├── App/
   ├── Features/
   │   ├── Drawing/
   │   ├── Notes/
   │   ├── Auth/
   │   └── Settings/
   ├── Services/
   ├── Widget/
   ├── Shared/
   │   ├── Models/
   │   ├── Extensions/
   │   └── Utilities/
   └── Resources/
   ```

2. Set up the main app files as outlined in the documentation

### Step 3: Add Dependencies

The app uses minimal external dependencies to keep it lightweight:

#### Firebase Integration

**Option 1: Using Xcode (Recommended)**
1. Open the project in Xcode (double-click the `.xcodeproj` file)
2. Go to **File** → **Add Package Dependencies**
3. Add Firebase SDK packages:
   ```
   https://github.com/firebase/firebase-ios-sdk.git
   ```
4. Select the following products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
5. Click **Add Package**
6. Close Xcode and continue editing in Cursor

**Option 2: Using Package.swift (Advanced)**
If your project uses Swift Package Manager, you can add dependencies directly in `Package.swift` or via Xcode's package manager.

#### No additional dependencies required for:
- PencilKit (built into iOS)
- WidgetKit (built into iOS)
- SwiftUI (built into iOS)

---

## Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `LoveNotes`
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

### Step 2: Add iOS App

1. In Firebase Console, click "Add app"
2. Select iOS platform
3. Enter your bundle identifier: `com.yourname.lovenotes`
4. Download `GoogleService-Info.plist`
5. In Cursor, add this file to your project root directory (drag and drop or use file explorer)
6. Add the Firebase SDK initialization code to your app (you'll do this in Cursor)

### Step 3: Configure Firebase Services

#### Firestore Database
1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Choose **Start in test mode** (we'll secure it later)
4. Select a location (choose closest to your users)

#### Authentication
1. Go to **Authentication**
2. Enable **Email/Password** sign-in method
3. Optionally enable **Sign in with Apple**

#### Storage
1. Go to **Storage**
2. Click "Get started"
3. Follow the setup wizard

---

## Widget Extension Setup

**Note**: Widget extension setup requires Xcode for target configuration. You'll edit the code in Cursor afterward.

### Step 1: Add Widget Target

1. Open the project in Xcode (double-click the `.xcodeproj` file)
2. Go to **File** → **New** → **Target**
3. Choose **Widget Extension**
4. Name it: `LoveNotesWidget`
5. Ensure the bundle identifier matches your main app with `.widget` suffix
6. Activate the scheme
7. Close Xcode and continue editing in Cursor

### Step 2: Configure App Groups

1. Open the project in Xcode
2. Select your main app target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **App Groups**
6. Create a new group: `group.com.yourname.lovenotes.widget`
7. Repeat for the widget target (select the same group)
8. Close Xcode and continue editing in Cursor

### Step 3: Link Widget and Main App

1. Open the project in Xcode
2. In your widget target, go to **General**
3. Under **Frameworks, Libraries, and Embedded Content**
4. Add your main app framework
5. Set embedding to **Embed & Sign**
6. Close Xcode and continue editing in Cursor

---

## Initial Code Implementation

### Step 1: Set Up Main App Structure

In Cursor, create the following files based on the documentation:

#### App/LoveNotesApp.swift
```swift
import SwiftUI
import Firebase

@main
struct LoveNotesApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .onAppear {
                    FirebaseApp.configure()
                }
        }
    }
}
```

#### App/ContentView.swift
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isSignedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}
```

### Step 2: Implement Basic Models

In Cursor, create the core data models in `Shared/Models/`:

#### Note.swift
#### User.swift
#### Couple.swift

(Use the code from DATA_MODELS.md)

### Step 3: Set Up Firebase Service

In Cursor, create `Services/FirebaseService.swift` with basic configuration:

```swift
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    
    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
```

### Step 4: Implement Authentication

In Cursor, create `Services/AuthService.swift` and `Features/Auth/` views:

(Use the code from FIREBASE_INTEGRATION.md and UI_COMPONENTS.md)

---

## Testing Setup

### Step 1: Simulator Testing

1. Open the project in Xcode (double-click the `.xcodeproj` file)
2. Select iOS Simulator (iPhone 15 Pro recommended) from the scheme menu
3. Build and run the project (⌘+R)
4. Test basic functionality:
   - App launch
   - Navigation
   - Authentication flow
5. Close Xcode and continue editing in Cursor

### Step 2: Device Testing

1. Open the project in Xcode
2. Connect your iPhone/iPad to your Mac
3. Select your device from the scheme menu
4. Build and run (⌘+R)
5. Test device-specific features:
   - PencilKit drawing
   - Camera permissions
   - Push notifications
6. Close Xcode and continue editing in Cursor

### Step 3: Widget Testing

1. Open the project in Xcode
2. Select the widget scheme from the scheme menu
3. Build and run the widget target
4. Add widget to home screen:
   - Long press on home screen
   - Tap "+" button
   - Search for "LoveNotes"
   - Add widget
5. Close Xcode and continue editing in Cursor

---

## Development Workflow

### Phase 1: Core Features (Week 1-2)

1. **Day 1-2**: Project setup and basic UI
   ```bash
   # Create git repository
   git init
   git add .
   git commit -m "Initial project setup"
   ```

2. **Day 3-4**: Drawing implementation
   - Implement PencilKit canvas
   - Add basic drawing tools
   - Test drawing functionality

3. **Day 5-7**: Authentication
   - Set up Firebase Auth
   - Create sign-up/sign-in flows
   - Test user creation

### Phase 2: Backend Integration (Week 3-4)

1. **Day 8-10**: Firebase integration
   - Configure Firestore
   - Implement real-time sync
   - Test data persistence

2. **Day 11-14**: Couple pairing
   - Create pairing system
   - Test partner connections
   - Implement note sharing

### Phase 3: Widget Development (Week 5-6)

1. **Day 15-18**: Widget setup
   - Create widget extension
   - Implement basic widget UI
   - Set up data sharing

2. **Day 19-21**: Widget features
   - Add interactive elements
   - Implement deep linking
   - Test widget functionality

---

## Common Issues & Solutions

### Issue 1: Firebase Configuration

**Problem**: "Firebase not configured" error
**Solution**: 
- Ensure `GoogleService-Info.plist` is in project root (check in Cursor's file explorer)
- Add `FirebaseApp.configure()` in app delegate (edit in Cursor)
- Check bundle identifier matches Firebase project (verify in Xcode if needed)

### Issue 2: Widget Data Sharing

**Problem**: Widget not showing data from main app
**Solution**:
- Verify App Groups are configured correctly
- Check bundle identifiers match
- Ensure UserDefaults is using correct suite name

### Issue 3: PencilKit Not Working

**Problem**: Drawing canvas not responding
**Solution**:
- Ensure device supports PencilKit
- Check canvas view delegate is set
- Verify drawing policy is set correctly

### Issue 4: Build Errors

**Problem**: "Cannot find type" errors
**Solution**:
- Ensure all files are added to target (check in Xcode's project navigator)
- Check import statements (verify in Cursor)
- Verify file locations in project structure (check in Cursor's file explorer)
- If files were created in Cursor, you may need to add them to the Xcode project manually

---

## Performance Optimization

### Drawing Performance
```swift
// Optimize drawing data size
func compressDrawingData(_ data: Data) -> Data {
    // Implement compression logic
    return data
}
```

### Firebase Queries
```swift
// Use efficient queries
firestore.collection("notes")
    .whereField("coupleId", isEqualTo: coupleId)
    .order(by: "createdAt", descending: true)
    .limit(to: 20) // Pagination
```

### Widget Memory
```swift
// Limit widget data size
let maxWidgetDataSize = 50 * 1024 * 1024 // 50MB
```

---

## Security Best Practices

### Firebase Rules
```javascript
// Secure Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

### Data Validation
```swift
// Validate user input
func validateEmail(_ email: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
}
```

---

## Next Steps

After completing the initial setup:

1. **Implement remaining features** following the roadmap
2. **Add comprehensive testing** (unit tests, UI tests)
3. **Optimize performance** and fix any issues
4. **Prepare for App Store submission**
5. **Create marketing materials** and launch plan

## Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [PencilKit Documentation](https://developer.apple.com/documentation/pencilkit/)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit/)
- [Firebase Documentation](https://firebase.google.com/docs)

### Sample Code
- [Apple SwiftUI Samples](https://developer.apple.com/tutorials/swiftui/)
- [Firebase iOS Samples](https://github.com/firebase/quickstart-ios)

### Design Resources
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

---

## Development Workflow with Cursor

### Daily Workflow

1. **Editing Code**: Use Cursor as your primary editor for all Swift files
2. **Building/Running**: Open Xcode when you need to:
   - Build and run the app
   - Test on simulator or device
   - Manage dependencies
   - Configure project settings
   - Debug with breakpoints
3. **File Management**: Create new files in Cursor, but ensure they're added to the Xcode project target
4. **Version Control**: Use Cursor's integrated Git features or terminal

### Tips for Cursor + Xcode Workflow

- Keep Xcode closed while editing to avoid file conflicts
- Use Cursor's terminal for Git commands and Swift Package Manager operations
- When creating new files in Cursor, remember to add them to the Xcode project target
- Use Xcode's build system for compilation and running
- Leverage Cursor's AI features for code generation and refactoring

## Support

If you encounter issues during setup:

1. Check the documentation files for detailed implementation guides
2. Review Apple's documentation for specific framework issues
3. Test on multiple devices and iOS versions
4. Join developer communities for help

Happy coding! 🚀