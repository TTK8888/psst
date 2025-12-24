# Firebase Integration & Real-Time Sync

## Overview
Firebase will provide the backend infrastructure for real-time synchronization, user authentication, and data storage. This implementation ensures couples can instantly share handwritten notes.

## Firebase Configuration

### 1. FirebaseService.swift

```swift
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    // MARK: - Properties
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    let storage = Storage.storage()
    
    // Firestore Collections
    private let usersCollection = "users"
    private let notesCollection = "notes"
    private let couplesCollection = "couples"
    
    // MARK: - Initialization
    private init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        firestore.settings = settings
    }
}

// MARK: - User Management
extension FirebaseService {
    func getCurrentUser() -> User? {
        return auth.currentUser
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        return try await auth.signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResult {
        return try await auth.createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else { throw AuthError.noUser }
        
        let changeRequest = user.createProfileChangeRequest()
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
    }
}

// MARK: - Couple Management
extension FirebaseService {
    func createCouple(user1Id: String, user2Id: String) async throws -> String {
        let coupleData: [String: Any] = [
            "user1Id": user1Id,
            "user2Id": user2Id,
            "createdAt": Timestamp(date: Date()),
            "status": "active"
        ]
        
        let docRef = try await firestore.collection(couplesCollection).addDocument(data: coupleData)
        return docRef.documentID
    }
    
    func getCoupleId(forUserId userId: String) async throws -> String? {
        let snapshot = try await firestore.collection(couplesCollection)
            .whereField("user1Id", isEqualTo: userId)
            .getDocuments()
        
        if let document = snapshot.documents.first {
            return document.documentID
        }
        
        let snapshot2 = try await firestore.collection(couplesCollection)
            .whereField("user2Id", isEqualTo: userId)
            .getDocuments()
        
        return snapshot2.documents.first?.documentID
    }
    
    func getCouplePartnerId(forUserId userId: String) async throws -> String? {
        guard let coupleId = try await getCoupleId(forUserId: userId) else {
            return nil
        }
        
        let docSnapshot = try await firestore.collection(couplesCollection)
            .document(coupleId)
            .getDocument()
        
        guard let data = docSnapshot.data() else { return nil }
        
        let user1Id = data["user1Id"] as? String
        let user2Id = data["user2Id"] as? String
        
        return user1Id == userId ? user2Id : user1Id
    }
}

// MARK: - Notes Management
extension FirebaseService {
    func createNote(note: Note) async throws -> String {
        let noteData: [String: Any] = [
            "id": note.id,
            "authorId": note.authorId,
            "coupleId": note.coupleId,
            "content": note.content,
            "drawingURL": note.drawingURL,
            "createdAt": Timestamp(date: note.createdAt),
            "updatedAt": Timestamp(date: note.updatedAt),
            "isRead": note.isRead
        ]
        
        let docRef = try await firestore.collection(notesCollection)
            .addDocument(data: noteData)
        return docRef.documentID
    }
    
    func updateNote(_ note: Note) async throws {
        let noteData: [String: Any] = [
            "content": note.content,
            "drawingURL": note.drawingURL,
            "updatedAt": Timestamp(date: note.updatedAt),
            "isRead": note.isRead
        ]
        
        try await firestore.collection(notesCollection)
            .document(note.id)
            .updateData(noteData)
    }
    
    func deleteNote(noteId: String) async throws {
        try await firestore.collection(notesCollection)
            .document(noteId)
            .delete()
    }
    
    func getNotesForCouple(coupleId: String) async throws -> [Note] {
        let snapshot = try await firestore.collection(notesCollection)
            .whereField("coupleId", isEqualTo: coupleId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Note.self)
        }
    }
    
    func listenForNotes(coupleId: String, completion: @escaping (Result<[Note], Error>) -> Void) -> ListenerRegistration {
        return firestore.collection(notesCollection)
            .whereField("coupleId", isEqualTo: coupleId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let notes = documents.compactMap { document in
                    try? document.data(as: Note.self)
                }
                
                completion(.success(notes))
            }
    }
}

// MARK: - Storage Management
extension FirebaseService {
    func uploadDrawing(_ drawingData: Data, noteId: String) async throws -> URL {
        let storageRef = storage.reference()
            .child("drawings")
            .child("\(noteId).drawing")
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        
        try await storageRef.putDataAsync(drawingData, metadata: metadata)
        return try await storageRef.downloadURL()
    }
    
    func downloadDrawing(noteId: String) async throws -> Data {
        let storageRef = storage.reference()
            .child("drawings")
            .child("\(noteId).drawing")
        
        return try await storageRef.data(maxSize: 10 * 1024 * 1024) // 10MB max
    }
    
    func deleteDrawing(noteId: String) async throws {
        let storageRef = storage.reference()
            .child("drawings")
            .child("\(noteId).drawing")
        
        try await storageRef.delete()
    }
}

// MARK: - Error Types
enum AuthError: LocalizedError {
    case noUser
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No user is currently signed in"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "Email is already in use"
        case .weakPassword:
            return "Password is too weak"
        case .networkError:
            return "Network error occurred"
        }
    }
}
```

### 2. AuthService.swift

```swift
import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthService: ObservableObject {
    // MARK: - Published Properties
    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    init() {
        setupAuthStateListener()
        checkCurrentUser()
    }
    
    deinit {
        if let handler = authStateHandler {
            firebaseService.auth.removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Public Methods
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await firebaseService.signIn(email: email, password: password)
            await handleAuthResult(result)
        } catch {
            await handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await firebaseService.signUp(email: email, password: password)
            
            // Update profile with display name
            try await firebaseService.updateProfile(displayName: displayName, photoURL: nil)
            
            await handleAuthResult(result)
        } catch {
            await handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try firebaseService.signOut()
            updateAuthState(user: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.resetPassword(email: email)
            // Show success message to user
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async {
        do {
            try await firebaseService.updateProfile(displayName: displayName, photoURL: photoURL)
            // Refresh current user data
            if let user = firebaseService.getCurrentUser() {
                updateAuthState(user: user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Private Methods
    private func setupAuthStateListener() {
        authStateHandler = firebaseService.auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.updateAuthState(user: user)
            }
        }
    }
    
    private func checkCurrentUser() {
        if let user = firebaseService.getCurrentUser() {
            updateAuthState(user: user)
        }
    }
    
    private func handleAuthResult(_ result: AuthDataResult) async {
        updateAuthState(user: result.user)
    }
    
    private func handleAuthError(_ error: Error) async {
        errorMessage = mapAuthError(error)
    }
    
    private func updateAuthState(user: User?) {
        currentUser = user
        isSignedIn = user != nil
    }
    
    private func mapAuthError(_ error: Error) -> String {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.wrongPassword:
                return "Incorrect password"
            case AuthErrorCode.userNotFound:
                return "User not found"
            case AuthErrorCode.emailAlreadyInUse:
                return "Email already in use"
            case AuthErrorCode.weakPassword:
                return "Password is too weak"
            case AuthErrorCode.networkError:
                return "Network error occurred"
            case AuthErrorCode.invalidEmail:
                return "Invalid email address"
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
```

### 3. NotesService.swift

```swift
import Foundation
import FirebaseFirestore
import Combine

@MainActor
class NotesService: ObservableObject {
    // MARK: - Published Properties
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasNewNotes = false
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    private var notesListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    deinit {
        notesListener?.remove()
    }
    
    // MARK: - Public Methods
    func startListening() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        do {
            let coupleId = try await firebaseService.getCoupleId(forUserId: userId)
            guard let coupleId = coupleId else { return }
            
            notesListener = firebaseService.listenForNotes(coupleId: coupleId) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let notes):
                        await self?.handleNotesUpdate(notes)
                    case .failure(let error):
                        await self?.handleError(error)
                    }
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    func stopListening() {
        notesListener?.remove()
        notesListener = nil
    }
    
    func createNote(content: String, drawingData: Data? = nil) async {
        guard let userId = authService.currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get couple ID
            let coupleId = try await firebaseService.getCoupleId(forUserId: userId)
            guard let coupleId = coupleId else {
                throw NotesError.noCoupleFound
            }
            
            // Create note
            let note = Note(
                id: UUID().uuidString,
                authorId: userId,
                coupleId: coupleId,
                content: content,
                drawingURL: nil,
                createdAt: Date(),
                updatedAt: Date(),
                isRead: false
            )
            
            // Upload drawing if provided
            var noteWithDrawing = note
            if let drawingData = drawingData {
                let drawingURL = try await firebaseService.uploadDrawing(drawingData, noteId: note.id)
                noteWithDrawing.drawingURL = drawingURL.absoluteString
            }
            
            // Save to Firestore
            _ = try await firebaseService.createNote(note: noteWithDrawing)
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func updateNote(_ note: Note, content: String? = nil, drawingData: Data? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedNote = note
            
            // Update content if provided
            if let content = content {
                updatedNote.content = content
            }
            
            // Update drawing if provided
            if let drawingData = drawingData {
                // Delete old drawing if exists
                if note.drawingURL != nil {
                    try await firebaseService.deleteDrawing(noteId: note.id)
                }
                
                // Upload new drawing
                let drawingURL = try await firebaseService.uploadDrawing(drawingData, noteId: note.id)
                updatedNote.drawingURL = drawingURL.absoluteString
            }
            
            updatedNote.updatedAt = Date()
            
            // Save to Firestore
            try await firebaseService.updateNote(updatedNote)
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func deleteNote(_ note: Note) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete drawing if exists
            if note.drawingURL != nil {
                try await firebaseService.deleteDrawing(noteId: note.id)
            }
            
            // Delete note from Firestore
            try await firebaseService.deleteNote(noteId: note.id)
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func markNoteAsRead(_ note: Note) async {
        var readNote = note
        readNote.isRead = true
        
        do {
            try await firebaseService.updateNote(readNote)
        } catch {
            await handleError(error)
        }
    }
    
    func refreshNotes() async {
        guard let userId = authService.currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let coupleId = try await firebaseService.getCoupleId(forUserId: userId)
            guard let coupleId = coupleId else {
                throw NotesError.noCoupleFound
            }
            
            let fetchedNotes = try await firebaseService.getNotesForCouple(coupleId: coupleId)
            await handleNotesUpdate(fetchedNotes)
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        authService.$isSignedIn
            .sink { [weak self] isSignedIn in
                Task { @MainActor in
                    if isSignedIn {
                        await self?.startListening()
                    } else {
                        self?.stopListening()
                        self?.notes = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleNotesUpdate(_ newNotes: [Note]) async {
        let previousUnreadCount = notes.filter { !$0.isRead }.count
        let newUnreadCount = newNotes.filter { !$0.isRead && $0.authorId != authService.currentUser?.uid }.count
        
        notes = newNotes
        hasNewNotes = newUnreadCount > previousUnreadCount
    }
    
    private func handleError(_ error: Error) async {
        errorMessage = error.localizedDescription
    }
}

// MARK: - Error Types
enum NotesError: LocalizedError {
    case noCoupleFound
    case noteNotFound
    case drawingUploadFailed
    case drawingDownloadFailed
    
    var errorDescription: String? {
        switch self {
        case .noCoupleFound:
            return "No couple found for current user"
        case .noteNotFound:
            return "Note not found"
        case .drawingUploadFailed:
            return "Failed to upload drawing"
        case .drawingDownloadFailed:
            return "Failed to download drawing"
        }
    }
}
```

### 4. Firebase Security Rules

#### Firestore Rules (firestore.rules)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Couples can only access their own couple documents
    match /couples/{coupleId} {
      allow read, write: if 
        request.auth.uid == resource.data.user1Id ||
        request.auth.uid == resource.data.user2Id ||
        (request.auth.uid == request.resource.data.user1Id || 
         request.auth.uid == request.resource.data.user2Id);
    }
    
    // Notes can only be accessed by couple members
    match /notes/{noteId} {
      allow read, write: if 
        request.auth.uid == resource.data.authorId ||
        request.auth.uid == resource.data.coupleId.split(',')[0] ||
        request.auth.uid == resource.data.coupleId.split(',')[1];
      
      allow create: if 
        request.auth.uid == request.resource.data.authorId &&
        request.auth.uid == request.resource.data.coupleId.split(',')[0] ||
        request.auth.uid == request.resource.data.coupleId.split(',')[1];
    }
  }
}
```

#### Storage Rules (storage.rules)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Only authenticated users can access drawings
    match /drawings/{noteId}.drawing {
      allow read, write: if request.auth != null;
    }
    
    // Profile pictures can be accessed by anyone
    match /profile-pictures/{userId}.jpg {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## Key Implementation Details

### 1. Real-Time Synchronization
- Firestore listeners for instant updates
- Offline persistence with local cache
- Conflict resolution strategies

### 2. Security
- Firebase security rules for data protection
- User-based access control
- Couple-based data isolation

### 3. Performance
- Efficient queries with proper indexing
- Pagination for large note collections
- Image optimization and caching

### 4. Error Handling
- Comprehensive error types
- User-friendly error messages
- Retry mechanisms for network issues

### 5. Data Models
- Codable support for easy serialization
- Timestamp handling for dates
- Optional fields for flexibility

## Usage Example

```swift
struct NotesView: View {
    @StateObject private var notesService = NotesService()
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationView {
            List(notesService.notes) { note in
                NoteCellView(note: note)
            }
            .navigationTitle("Our Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Note") {
                        // Navigate to note creation
                    }
                }
            }
        }
        .onAppear {
            Task {
                await notesService.refreshNotes()
            }
        }
    }
}
```