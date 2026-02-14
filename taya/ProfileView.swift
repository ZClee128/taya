//
//  ProfileView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showingDeleteAlert = false
    @State private var showStore = false
    @State private var showEditProfile = false
    @State private var showInsufficientCoinsAlert = false
    @State private var showEditProfileAlert = false
    
    let editCost = 32
    
    // Fallback to mock user if session is somehow empty, though ContentView prevents this
    var user: User {
        sessionManager.currentUser ?? MockData.currentUser
    }
    
    var userPosts: [Post] {
        MockData.posts.filter { $0.user.id == user.id }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        AvatarView(username: user.username, size: 80, avatarName: user.avatarName)
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(user.username)
                                .font(.title)
                                .bold()
                            Text(user.bio)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // Coin & Edit Profile Section
                    HStack {
                        // Coin Balance
                        Button(action: {
                            showStore = true
                        }) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.yellow)
                                Text("\(sessionManager.coinBalance)")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Edit Profile Button
                        Button(action: {
                            if sessionManager.coinBalance >= editCost {
                                showEditProfileAlert = true
                            } else {
                                showInsufficientCoinsAlert = true
                            }
                        }) {
                            Text("Edit Profile (32 Coins)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    HStack {
                        Spacer()
                        VStack {
                            Text("\(userPosts.count)")
                                .font(.headline)
                            Text("Posts")
                                .font(.caption)
                        }
                        Spacer()
                        VStack {
                            Text("0")
                                .font(.headline)
                            Text("Followers")
                                .font(.caption)
                        }
                        Spacer()
                        VStack {
                            Text("0")
                                .font(.headline)
                            Text("Following")
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .padding(.vertical)

                    // Post Grid
                    VStack(spacing: 2) {
                        ForEach(gridRows(posts: userPosts), id: \.self) { rowPosts in
                            HStack(spacing: 2) {
                                ForEach(rowPosts) { post in
                                    NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                                        ZStack {
                                            if let uiImage = UIImage(named: post.imageName) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                                    .clipped()
                                            } else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpeg"), let uiImage = UIImage(contentsOfFile: path) {
                                                 Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                                    .clipped()
                                            } else {
                                                Image(systemName: post.imageName)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .padding(10)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .aspectRatio(1, contentMode: .fit)
                                        .background(Color.secondary.opacity(0.1))
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Preserve image appearance
                                }
                                // Fill empty spaces
                                ForEach(0..<(3 - rowPosts.count), id: \.self) { _ in
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 30)
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("Delete Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .alert(isPresented: $showingDeleteAlert) {
                        Alert(title: Text("Delete Account"),
                              message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                              primaryButton: .destructive(Text("Delete")) {
                                sessionManager.deleteAccount()
                              },
                              secondaryButton: .cancel())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitle("Profile 👤", displayMode: .inline)
            .sheet(isPresented: $showStore) {
                StoreView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(sessionManager: sessionManager)
            }
            .alert(isPresented: $showInsufficientCoinsAlert) {
                Alert(
                    title: Text("Insufficient Coins"),
                    message: Text("You need \(editCost) coins to edit your profile. Would you like to recharge?"),
                    primaryButton: .default(Text("Go to Store")) {
                        showStore = true
                    },
                    secondaryButton: .cancel()
                )
            }
            // We need a second alert for confirmation, but iOS 13 only supports one .alert per view nicely.
            // We can workaround or simpler: just do the check action logic in the button.
            // Let's use a workaround: Bind different alerts? No, simpler to use logic.
            // Actually, let's keep it simple: "Confirm spend" alert.
        }
        // Additional alert attachment for confirmation specific logic
        .alert(isPresented: $showEditProfileAlert) {
             Alert(
                 title: Text("Edit Profile"),
                 message: Text("This will cost \(editCost) coins. Proceed?"),
                 primaryButton: .default(Text("Start Editing")) {
                     // Coin deduction moved to EditProfileView upon saving
                     showEditProfile = true
                 },
                 secondaryButton: .cancel()
             )
         }
    }

    func gridRows(posts: [Post]) -> [[Post]] {
        var rows: [[Post]] = []
        for i in stride(from: 0, to: posts.count, by: 3) {
            var row: [Post] = []
            for j in 0..<3 {
                if i + j < posts.count {
                    row.append(posts[i + j])
                }
            }
            rows.append(row)
        }
        return rows
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(sessionManager: SessionManager())
    }
}
