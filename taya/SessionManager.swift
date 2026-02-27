import SwiftUI
import Combine

/// Manages user authentication and session state.
/// Provides Sign In with Apple integration and local session persistence.
class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserProfile = SampleData.currentUser
    @Published var hasAgreedToTerms: Bool = false

    private let loginKey = "taya_user_logged_in"
    private let nameKey = "taya_user_name"
    private let bioKey = "taya_user_bio"

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: loginKey)
        if isLoggedIn {
            loadProfile()
        }
    }

    /// Signs the user in and persists session.
    func signIn(name: String? = nil) {
        let randomSuffix = Int.random(in: 1000...9999)
        let displayName = name ?? "Wellness \(randomSuffix)"
        currentUser.displayName = displayName
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        saveProfile()
    }

    /// Signs the user out and clears session.
    func signOut() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: bioKey)
    }

    /// Deletes the user account — clears all data and returns to login.
    func deleteAccount() {
        // Clear session
        isLoggedIn = false
        hasAgreedToTerms = false
        
        let randomSuffix = Int.random(in: 1000...9999)
        currentUser = UserProfile(
            id: UUID(),
            displayName: "Wellness \(randomSuffix)",
            bio: "Exploring balance and mindful living.",
            avatarIcon: "person.crop.circle.fill"
        )

        // Clear all stored data
        UserDefaults.standard.set(false, forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: bioKey)

        // Clear coin balance and perks
        StoreManager.shared.resetAllData()

        // Clear chat history
        ChatManager.shared.resetAllData()
    }

    /// Updates and persists user profile.
    func updateProfile(name: String, bio: String) {
        currentUser.displayName = name
        currentUser.bio = bio
        saveProfile()
    }

    private func saveProfile() {
        UserDefaults.standard.set(currentUser.displayName, forKey: nameKey)
        UserDefaults.standard.set(currentUser.bio, forKey: bioKey)
    }

    private func loadProfile() {
        if let name = UserDefaults.standard.string(forKey: nameKey) {
            currentUser.displayName = name
        }
        if let bio = UserDefaults.standard.string(forKey: bioKey) {
            currentUser.bio = bio
        }
    }
}
