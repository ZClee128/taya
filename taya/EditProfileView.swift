//
//  EditProfileView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var username: String
    @State private var bio: String
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        _username = State(initialValue: sessionManager.currentUser?.username ?? "")
        _bio = State(initialValue: sessionManager.currentUser?.bio ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Public Info")) {
                    TextField("Username", text: $username)
                    TextField("Bio", text: $bio)
                }
                
                Section {
                    Button(action: saveProfile) {
                        Text("Save Changes")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func saveProfile() {
        // Deduct coins here
        if sessionManager.spendCoins(32) {
            guard var user = sessionManager.currentUser else { return }
            user.username = username
            user.bio = bio
            sessionManager.currentUser = user
            // Force save
            if let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "currentUser")
            }
            presentationMode.wrappedValue.dismiss()
        } else {
            // Should not happen if pre-checked, but good safety
             // In iOS 13 simple alert is hard from function without state, 
             // but we can just ignore or print as this flow is gated by ProfileView check.
             print("Insufficient coins to save")
        }
    }
}
