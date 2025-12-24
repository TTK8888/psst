# UI Components & Views

## Overview
This document contains all the SwiftUI views and UI components for the LoveNotes app. Each component is designed to be reusable, accessible, and follows Apple's Human Interface Guidelines.

## Core Views

### 1. Main App Structure

#### LoveNotesApp.swift

```swift
import SwiftUI
import Firebase

@main
struct LoveNotesApp: App {
    // MARK: - Dependencies
    @StateObject private var authService = AuthService()
    @StateObject private var notificationService = NotificationService()
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(notificationService)
                .onAppear {
                    configureApp()
                }
        }
    }
    
    // MARK: - Configuration
    private func configureApp() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Configure notifications
        notificationService.requestPermission()
        
        // Configure appearance
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}
```

#### ContentView.swift

```swift
import SwiftUI

struct ContentView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - Body
    var body: some View {
        Group {
            if authService.isSignedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authService.isSignedIn)
    }
}

struct MainTabView: View {
    // MARK: - State
    @State private var selectedTab = 0
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            NotesListView()
                .tabItem {
                    Label("Notes", systemImage: "heart.text.square")
                }
                .tag(0)
            
            DrawingView()
                .tabItem {
                    Label("Draw", systemImage: "pencil.tip")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .accentColor(AppColors.primary)
    }
}
```

### 2. Authentication Views

#### AuthView.swift

```swift
import SwiftUI

struct AuthView: View {
    // MARK: - State
    @State private var isShowingSignUp = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo and Title
                authHeaderView
                
                // Auth Form
                if isShowingSignUp {
                    SignUpView()
                } else {
                    SignInView()
                }
                
                // Toggle Auth Mode
                authToggleView
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.primary.opacity(0.1), AppColors.secondary.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
        }
    }
    
    private var authHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            
            Text("LoveNotes")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Share handwritten notes with your loved one")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var authToggleView: some View {
        HStack {
            Text(isShowingSignUp ? "Already have an account?" : "Don't have an account?")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                withAnimation(.easeInOut) {
                    isShowingSignUp.toggle()
                }
            }) {
                Text(isShowingSignUp ? "Sign In" : "Sign Up")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
            }
        }
    }
}
```

#### SignInView.swift

```swift
import SwiftUI

struct SignInView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingResetPassword = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            CustomTextField(
                text: $email,
                placeholder: "Email",
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .none
            )
            
            // Password Field
            CustomSecureField(
                text: $password,
                placeholder: "Password",
                icon: "lock"
            )
            
            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    isShowingResetPassword = true
                }
                .font(.caption)
                .foregroundColor(AppColors.primary)
            }
            
            // Sign In Button
            ActionButton(
                title: "Sign In",
                isLoading: authService.isLoading,
                action: signIn
            )
            
            // Error Message
            if let errorMessage = authService.errorMessage {
                ErrorMessageView(message: errorMessage)
            }
        }
        .sheet(isPresented: $isShowingResetPassword) {
            ResetPasswordView()
        }
        .disabled(authService.isLoading)
    }
    
    // MARK: - Actions
    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
        }
    }
}
```

#### SignUpView.swift

```swift
import SwiftUI

struct SignUpView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !displayName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Display Name Field
            CustomTextField(
                text: $displayName,
                placeholder: "Your Name",
                icon: "person"
            )
            
            // Email Field
            CustomTextField(
                text: $email,
                placeholder: "Email",
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .none
            )
            
            // Password Field
            CustomSecureField(
                text: $password,
                placeholder: "Password",
                icon: "lock"
            )
            
            // Confirm Password Field
            CustomSecureField(
                text: $confirmPassword,
                placeholder: "Confirm Password",
                icon: "lock.fill"
            )
            
            // Password Requirements
            if !password.isEmpty {
                passwordRequirementsView
            }
            
            // Sign Up Button
            ActionButton(
                title: "Sign Up",
                isLoading: authService.isLoading,
                isDisabled: !isFormValid,
                action: signUp
            )
            
            // Error Message
            if let errorMessage = authService.errorMessage {
                ErrorMessageView(message: errorMessage)
            }
        }
        .disabled(authService.isLoading)
    }
    
    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Password Requirements:")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                RequirementRow(
                    text: "At least 6 characters",
                    isMet: password.count >= 6
                )
                RequirementRow(
                    text: "Passwords match",
                    isMet: password == confirmPassword && !confirmPassword.isEmpty
                )
            }
        }
    }
    
    // MARK: - Actions
    private func signUp() {
        Task {
            await authService.signUp(email: email, password: password, displayName: displayName)
        }
    }
}

struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundColor(isMet ? .green : .gray)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(isMet ? .green : .gray)
        }
    }
}
```

### 3. Notes Views

#### NotesListView.swift

```swift
import SwiftUI

struct NotesListView: View {
    // MARK: - State Objects
    @StateObject private var viewModel = NotesViewModel()
    
    // MARK: - State
    @State private var isShowingCreateNote = false
    @State private var selectedNote: Note?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                if viewModel.notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Our Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingCreateNote = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshNotes()
            }
            .sheet(isPresented: $isShowingCreateNote) {
                CreateNoteView()
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Notes Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start by leaving a note for your partner")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create First Note") {
                isShowingCreateNote = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.notes) { note in
                    NoteCellView(note: note)
                        .onTapGesture {
                            selectedNote = note
                        }
                }
            }
            .padding()
        }
    }
}
```

#### NoteCellView.swift

```swift
import SwiftUI

struct NoteCellView: View {
    // MARK: - Properties
    let note: Note
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            noteHeader
            
            // Content
            noteContent
            
            // Footer
            noteFooter
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var noteHeader: some View {
        HStack {
            // Author Avatar
            Circle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(initials)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("From your partner")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(note.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unread Indicator
            if !note.isRead {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    @ViewBuilder
    private var noteContent: some View {
        if note.hasDrawing {
            drawingPreview
        } else if !note.content.isEmpty {
            Text(note.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var drawingPreview: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(AppColors.secondary.opacity(0.1))
            .frame(height: 120)
            .overlay(
                VStack {
                    Image(systemName: "pencil.tip")
                        .font(.title2)
                        .foregroundColor(AppColors.secondary)
                    
                    Text("Handwritten Note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
    
    private var noteFooter: some View {
        HStack {
            if note.hasDrawing && !note.content.isEmpty {
                Text("Drawing + Message")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if note.hasDrawing {
                Text("Drawing")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "heart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var initials: String {
        // This would come from user data
        return "YP" // Your Partner
    }
    
    private var cardBackground: some Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.white)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.1)
    }
}
```

### 4. Drawing Views

#### DrawingView.swift

```swift
import SwiftUI
import PencilKit

struct DrawingView: View {
    // MARK: - State Objects
    @StateObject private var viewModel = DrawingViewModel()
    
    // MARK: - State
    @State private var isShowingTools = true
    @State private var isShowingSaveOptions = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drawing Canvas
                drawingCanvas
                
                // Drawing Tools
                if isShowingTools {
                    DrawingToolsView(
                        selectedTool: $viewModel.selectedTool,
                        selectedColor: $viewModel.selectedColor,
                        strokeWidth: $viewModel.strokeWidth,
                        toolPickerVisible: $isShowingTools
                    )
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Handle cancel
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Undo Button
                        Button(action: viewModel.undoLastStroke) {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(viewModel.currentDrawing.bounds.isEmpty)
                        
                        // Clear Button
                        Button(action: viewModel.clearCanvas) {
                            Image(systemName: "trash")
                        }
                        
                        // Save Button
                        Button("Save") {
                            isShowingSaveOptions = true
                        }
                        .disabled(viewModel.currentDrawing.bounds.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingSaveOptions) {
                SaveNoteView(drawing: viewModel.currentDrawing)
            }
        }
    }
    
    private var drawingCanvas: some View {
        DrawingCanvasView(
            drawing: $viewModel.currentDrawing,
            toolPickerVisible: $isShowingTools
        )
        .background(Color(.systemBackground))
        .clipped()
    }
}
```

#### SaveNoteView.swift

```swift
import SwiftUI
import PencilKit

struct SaveNoteView: View {
    // MARK: - Properties
    let drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var message = ""
    @State private var isSaving = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Drawing Preview
                drawingPreview
                
                // Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a message (optional)")
                        .font(.headline)
                    
                    TextField("Write something sweet...", text: $message, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Save Button
                ActionButton(
                    title: "Send to Partner",
                    isLoading: isSaving,
                    action: saveNote
                )
            }
            .padding()
            .navigationTitle("Send Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var drawingPreview: some View {
        VStack(spacing: 8) {
            Text("Your Drawing")
                .font(.caption)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    // Drawing preview would go here
                    Image(systemName: "pencil.tip")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
        }
    }
    
    // MARK: - Actions
    private func saveNote() {
        isSaving = true
        
        Task {
            // Convert drawing to data
            if let drawingData = drawing.dataRepresentation() {
                // Save note with drawing and message
                // await notesService.createNote(content: message, drawingData: drawingData)
            }
            
            isSaving = false
            dismiss()
        }
    }
}
```

### 5. Custom UI Components

#### CustomTextField.swift

```swift
import SwiftUI

struct CustomTextField: View {
    // MARK: - Bindings
    @Binding var text: String
    
    // MARK: - Properties
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

#### CustomSecureField.swift

```swift
import SwiftUI

struct CustomSecureField: View {
    // MARK: - Bindings
    @Binding var text: String
    
    // MARK: - Properties
    let placeholder: String
    let icon: String
    
    // MARK: - State
    @State private var isSecure = true
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primary)
                .frame(width: 20)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

#### ActionButton.swift

```swift
import SwiftUI

struct ActionButton: View {
    // MARK: - Properties
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    // MARK: - Initialization
    init(title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(buttonBackground)
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isDisabled ? 0.98 : 1.0)
        .animation(.easeInOut, value: isDisabled)
    }
    
    private var buttonBackground: Color {
        if isDisabled {
            return Color.gray
        } else {
            return AppColors.primary
        }
    }
}
```

#### PrimaryButtonStyle.swift

```swift
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.primary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}
```

#### ErrorMessageView.swift

```swift
import SwiftUI

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}
```

### 6. Profile & Settings Views

#### ProfileView.swift

```swift
import SwiftUI

struct ProfileView: View {
    // MARK: - Environment Objects
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    @State private var isShowingEditProfile = false
    @State private var isShowingSettings = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Partner Status
                    partnerStatusView
                    
                    // Quick Actions
                    quickActionsView
                    
                    // App Info
                    appInfoView
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Profile") {
                            isShowingEditProfile = true
                        }
                        
                        Button("Settings") {
                            isShowingSettings = true
                        }
                        
                        Button("Sign Out") {
                            authService.signOut()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(initials)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                )
            
            // User Info
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var partnerStatusView: some View {
        VStack(spacing: 12) {
            Text("Partner Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.primary.opacity(0.1))
                .frame(height: 80)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primary)
                        
                        Text("Connected with your partner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ActionRow(
                    title: "Invite Partner",
                    icon: "person.badge.plus",
                    color: .blue
                ) {
                    // Handle invite
                }
                
                ActionRow(
                    title: "Widget Settings",
                    icon: "square.grid.2x2",
                    color: .green
                ) {
                    // Handle widget settings
                }
                
                ActionRow(
                    title: "Help & Support",
                    icon: "questionmark.circle",
                    color: .orange
                ) {
                    // Handle help
                }
            }
        }
    }
    
    private var appInfoView: some View {
        VStack(spacing: 12) {
            Text("About")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                InfoRow(title: "Version", value: appVersion)
                InfoRow(title: "Build", value: buildNumber)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var initials: String {
        guard let user = authService.currentUser else { return "?" }
        return user.displayName?.prefix(2).map(String.init).joined() ?? "U"
    }
    
    private var displayName: String {
        return authService.currentUser?.displayName ?? "User"
    }
    
    private var email: String {
        return authService.currentUser?.email ?? "user@example.com"
    }
    
    private var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

struct ActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

## Usage Examples

### Custom Text Field

```swift
CustomTextField(
    text: $email,
    placeholder: "Enter your email",
    icon: "envelope",
    keyboardType: .emailAddress,
    autocapitalization: .none
)
```

### Action Button

```swift
ActionButton(
    title: "Sign Up",
    isLoading: authService.isLoading,
    isDisabled: !isFormValid
) {
    await signUp()
}
```

### Note Cell

```swift
NoteCellView(note: note)
    .onTapGesture {
        selectedNote = note
    }
```

This comprehensive UI component library provides all the necessary views and components for building a beautiful, functional, and accessible LoveNotes app that follows Apple's design guidelines and provides an excellent user experience.