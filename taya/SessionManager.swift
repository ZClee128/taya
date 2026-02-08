//
//  SessionManager.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import Foundation
import Combine
import SwiftUI

class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var conversations: [Conversation] = []
    @Published var blockedUserIds: [UUID] = []
    @Published var coinBalance: Int = 0
    
    // Quick random names for account generation
    private let randomNames = ["StarWalker", "NebulaSeeker", "CosmicDust", "PlanetHunter", "AstroGeek", "MoonChild", "GalaxyRider", "SolarWind", "CometChaser", "VoidVoyager"]
    private let randomAvatars = ["person.circle.fill", "moon.stars.fill", "star.circle.fill", "sparkles", "sun.max.fill"]
    
    init() {
        loadSession()
    }
    
    func createAccount() {
        // Simulate random account generation
        let randomName = randomNames.randomElement() ?? "User\(Int.random(in: 1000...9999))"
        let randomAvatar = randomAvatars.randomElement() ?? "person.circle.fill"
        let newUser = User(username: randomName, bio: "Just joined Taya! Ready to explore the universe.", avatarName: randomAvatar)
        
        self.currentUser = newUser
        self.isLoggedIn = true
        saveUser(newUser)
        
        // Generate new conversations for the new account
        generateNewConversations()
        
        // Initial bonus
        addCoins(10)
    }
    
    func deleteAccount() {
        self.currentUser = nil
        self.isLoggedIn = false
        self.conversations = []
        self.blockedUserIds = []
        self.coinBalance = 0
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "conversations")
        UserDefaults.standard.removeObject(forKey: "blockedUserIds")
        UserDefaults.standard.removeObject(forKey: "coinBalance")
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
