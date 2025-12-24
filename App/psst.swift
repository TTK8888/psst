import Firebase
import SwiftUI

@main
struct psstApp: App {
    @Stateobject private var authService = AuthService()

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
