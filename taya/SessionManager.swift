//
//  SessionManager.swift
//  taya
//
//  Created by Developer on 2025/10/12.
//

import Foundation
import Combine
import SwiftUI
import AuthenticationServices

class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var conversations: [Conversation] = []
    @Published var blockedUserIds: [UUID] = []
    @Published var coinBalance: Int = 0
    @Published var authError: String?
    
    // Apple Sign In user identifier
    private var appleUserID: String? {
        get { UserDefaults.standard.string(forKey: "appleUserID") }
        set { UserDefaults.standard.set(newValue, forKey: "appleUserID") }
    }
    
    private let randomAvatars = ["person.circle.fill", "moon.stars.fill", "star.circle.fill", "sparkles", "sun.max.fill"]
    
    init() {
        loadSession()
        checkAppleCredentialState()
    }
    
    // MARK: - Sign in with Apple
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                self.appleUserID = userID
                
                // Try to restore previously saved user for this Apple ID
                let userKey = "appleUser_\(userID)"
                if let data = UserDefaults.standard.data(forKey: userKey),
                   let existingUser = try? JSONDecoder().decode(User.self, from: data) {
                    self.currentUser = existingUser
                    saveUser(existingUser)
                } else {
                    // Build display name from Apple credential
                    var displayName = ""
                    if let fullName = appleIDCredential.fullName {
                        let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
                        if !parts.isEmpty {
                            displayName = parts.joined(separator: " ")
                        }
                    }
                    
                    // Use email prefix as fallback
                    if displayName.isEmpty, let email = appleIDCredential.email {
                        displayName = String(email.prefix(while: { $0 != "@" }))
                    }
                    
                    // Generate unique name from Apple user ID if still empty
                    if displayName.isEmpty {
                        let names = ["StarWalker", "CosmicRay", "NebulaStar", "MoonGazer", "SkyLens",
                                     "OrbitMind", "AstroVue", "DeepField", "NovaSpot", "SolarWind",
                                     "PulsarFan", "GalaxyEye", "CometTrail", "ZenithSky", "LunarPath"]
                        let hash = abs(userID.hashValue)
                        let suffix = hash % 10000
                        let name = names[hash % names.count]
                        displayName = "\(name)\(suffix)"
                    }
                    
                    // Create new user
                    let randomAvatar = randomAvatars.randomElement() ?? "person.circle.fill"
                    let newUser = User(
                        username: displayName,
                        bio: "Exploring the cosmos with Taya ✨",
                        avatarName: randomAvatar
                    )
                    self.currentUser = newUser
                    saveUser(newUser)
                    // Also save under Apple ID key for future sign-ins
                    if let data = try? JSONEncoder().encode(newUser) {
                        UserDefaults.standard.set(data, forKey: userKey)
                    }
                }
                
                self.isLoggedIn = true
                self.authError = nil
                
                // Generate conversations if needed
                if self.conversations.isEmpty {
                    generateNewConversations()
                }
                
                // Welcome bonus for new users
                if coinBalance == 0 {
                    addCoins(10)
                }
            }
        case .failure(let error):
            // Don't show error if user cancelled
            if (error as? ASAuthorizationError)?.code != .canceled {
                self.authError = "Sign in failed. Please try again."
            }
            print("Apple Sign In error: \(error.localizedDescription)")
        }
    }
    
    /// Check if the Apple credential is still valid on app launch
    private func checkAppleCredentialState() {
        guard let userID = appleUserID else { return }
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] state, _ in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    break // Credential is still valid
                case .revoked:
                    // User explicitly revoked access — sign out
                    self?.signOut()
                case .notFound:
                    // Can happen on simulator or if Apple servers are unreachable
                    // Don't sign out — keep local session
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    /// Sign out — user can sign back in with the same Apple ID
    func signOut() {
        self.currentUser = nil
        self.isLoggedIn = false
        // Keep conversations, coins, blocked users, and appleUserID
        // so they are restored when user signs back in
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    /// Delete account — removes everything, user must create a new account
    func deleteAccount() {
        self.currentUser = nil
        self.isLoggedIn = false
        self.conversations = []
        self.blockedUserIds = []
        self.coinBalance = 0
        self.appleUserID = nil
        // Clear ALL data including Apple ID association
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "conversations")
        UserDefaults.standard.removeObject(forKey: "blockedUserIds")
        UserDefaults.standard.removeObject(forKey: "coinBalance")
        UserDefaults.standard.removeObject(forKey: "appleUserID")
    }
    
    func markConversationAsRead(user: User) {
        if let index = conversations.firstIndex(where: { $0.user.id == user.id }) {
            conversations[index].unreadCount = 0
            saveConversations(conversations)
        }
    }
    
    func blockUser(_ user: User) {
        if !blockedUserIds.contains(user.id) {
            blockedUserIds.append(user.id)
            saveBlockedUsers()
            // Remove conversation with blocked user if exists
            conversations.removeAll { $0.user.id == user.id }
            saveConversations(conversations)
        }
    }
    
    func reportUser(_ user: User) {
        // Mock report - in real app would send to server
        print("Reported user: \(user.username)")
    }
    
    private func saveBlockedUsers() {
        if let data = try? JSONEncoder().encode(blockedUserIds) {
            UserDefaults.standard.set(data, forKey: "blockedUserIds")
        }
    }
    
    private func loadSession() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isLoggedIn = true
        }
        
        // Load coins
        self.coinBalance = UserDefaults.standard.integer(forKey: "coinBalance")
        
        var loaded = false
        if let data = UserDefaults.standard.data(forKey: "conversations") {
            // Attempt to decode. If it fails (e.g. migration: missing 'messages' key), we fall through.
            if let convs = try? JSONDecoder().decode([Conversation].self, from: data) {
                self.conversations = convs
                loaded = true
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "blockedUserIds"),
           let blocked = try? JSONDecoder().decode([UUID].self, from: data) {
            self.blockedUserIds = blocked
        }
        
        // If logged in but conversations missing/failed to load, generate defaults
        if self.isLoggedIn && (!loaded || self.conversations.isEmpty) {
            generateNewConversations()
        }
    }
    
    func addCoins(_ amount: Int) {
        coinBalance += amount
        saveCoins()
    }
    
    func spendCoins(_ amount: Int) -> Bool {
        if coinBalance >= amount {
            coinBalance -= amount
            saveCoins()
            return true
        }
        return false
    }
    
    private func saveCoins() {
        UserDefaults.standard.set(coinBalance, forKey: "coinBalance")
    }
    
    private func saveUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }
    
    func sendMessage(to user: User, content: String) {
        if let index = conversations.firstIndex(where: { $0.user.id == user.id }) {
            var conversation = conversations[index]
            let newMessage = Message(content: content, isCurrentUser: true, timestamp: Date())
            conversation.messages.append(newMessage)
            conversation.lastMessage = content
            conversation.time = "Just now"
            conversations[index] = conversation
            saveConversations(conversations)
        }
    }
    
    private func generateNewConversations() {
        // Create some fresh mock conversations with initial messages
        let newConversations = [
            Conversation(user: User(username: "CosmicRay", bio: "Astro photographer", avatarName: "person.fill"), lastMessage: "Did you see standard comet?", unreadCount: Int.random(in: 0...3), time: "10:30 AM", messages: [
                Message(content: "Hey, are you going to the star party?", isCurrentUser: false, timestamp: Date().addingTimeInterval(-86400)),
                Message(content: "Did you see standard comet?", isCurrentUser: false, timestamp: Date().addingTimeInterval(-3600))
            ]),
            Conversation(user: User(username: "LunaLove", bio: "Moon walker", avatarName: "moon.stars.fill"), lastMessage: "Nice photo!", unreadCount: 0, time: "Yesterday", messages: [
                Message(content: "Your moon shot is incredible!", isCurrentUser: false, timestamp: Date().addingTimeInterval(-90000)),
                Message(content: "Thanks! Used my new telescope.", isCurrentUser: true, timestamp: Date().addingTimeInterval(-88000)),
                Message(content: "Nice photo!", isCurrentUser: false, timestamp: Date().addingTimeInterval(-86400))
            ]),
            Conversation(user: User(username: "StarWalker", bio: "Observer", avatarName: "star.circle.fill"), lastMessage: "Clear skies tonight?", unreadCount: Int.random(in: 0...1), time: "Mon", messages: [
                Message(content: "Clear skies tonight?", isCurrentUser: false, timestamp: Date().addingTimeInterval(-172800))
            ])
        ]
        self.conversations = newConversations
        saveConversations(newConversations)
    }
    
    private func saveConversations(_ conversations: [Conversation]) {
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "conversations")
        }
    }
}
