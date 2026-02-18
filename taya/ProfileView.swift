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
    
    // Fallback to mock user if session is somehow empty
    var user: User {
        sessionManager.currentUser ?? MockData.currentUser
    }
    
    var userPosts: [Post] {
        MockData.posts.filter { $0.user.id == user.id }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    
                    // Banner Image
                    ZStack(alignment: .bottomLeading) {
                        if let banner = user.bannerName, let path = Bundle.main.path(forResource: banner, ofType: nil), let uiImage = UIImage(contentsOfFile: path) { // Trying generic loading
                             Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipped()
                        } else {
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 150)
                        }
                        
                        // Avatar Overlay
                        HStack(alignment: .bottom) {
                            AvatarView(username: user.username, size: 80, avatarName: user.avatarName)
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .padding(.leading, 20)
                                .offset(y: 40) // Push down
                            
                            Spacer()
                            
                            // Edit Profile Button (Small version on banner)
                            Button(action: {
                                if sessionManager.coinBalance >= editCost {
                                    showEditProfileAlert = true
                                } else {
                                    showInsufficientCoinsAlert = true
                                }
                            }) {
                                Text("Edit")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(20)
                            }
                            .padding(.bottom, 10)
                            .padding(.trailing, 20)
                        }
                    }
                    .padding(.bottom, 40) // Space for avatar offset
                    .alert(isPresented: $showEditProfileAlert) {
                        Alert(
                             title: Text("Edit Profile"),
                             message: Text("This will cost \(editCost) coins. Proceed?"),
                             primaryButton: .default(Text("Start Editing")) {
                                 showEditProfile = true
                             },
                             secondaryButton: .cancel()
                         )
                    }
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(user.username)
                                .font(.title)
                                .bold()
                            
                            ForEach(user.badges, id: \.self) { badge in
                                if badge == "Verified" {
                                    Image(systemName: "checkmark.circle.fill") // checkmark.seal.fill is iOS 14+
                                        .foregroundColor(.blue)
                                } else if badge == "Pro" {
                                    Text("PRO")
                                        .font(.system(size: 10, weight: .bold)) // caption2 is iOS 14+
                                        .padding(4)
                                        .background(Color.yellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        Text(user.bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Coin Balance Row
                    HStack {
                        Button(action: {
                             showStore = true
                        }) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.yellow)
                                Text("\(sessionManager.coinBalance) Coins")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Stats Row
                    HStack {
                        Spacer()
                        VStack {
                            if #available(iOS 14.0, *) {
                                Text("\(userPosts.count)")
                                    .font(.title2)
                                    .bold()
                            } else {
                                // Fallback on earlier versions
                            }
                            Text("Posts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack {
                            if #available(iOS 14.0, *) {
                                Text("1.2k")
                                    .font(.title2)
                                    .bold()
                            } else {
                                // Fallback on earlier versions
                            }
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack {
                            if #available(iOS 14.0, *) {
                                Text("450")
                                    .font(.title2)
                                    .bold()
                            } else {
                                // Fallback on earlier versions
                            }
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)

                    Divider()
                    
                    // Post Grid (iOS 13 Compatible)
                    VStack(spacing: 2) {
                        ForEach(chunkedPosts(), id: \.self) { rowPosts in
                            HStack(spacing: 2) {
                                ForEach(rowPosts) { post in
                                    NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                                        ZStack {
                                            if let uiImage = UIImage(named: post.imageName) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(minWidth: 0, maxWidth: .infinity)
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .clipped()
                                            } else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpeg"), let uiImage = UIImage(contentsOfFile: path) {
                                                 Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(minWidth: 0, maxWidth: .infinity)
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .clipped()
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .overlay(
                                                        Image(systemName: post.imageName)
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                // Filler for last row
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
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true) // Hide nav bar to show banner
            .sheet(isPresented: $showStore) {
                StoreView(sessionManager: sessionManager)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(sessionManager: sessionManager)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(title: Text("Delete Account"),
                      message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                      primaryButton: .destructive(Text("Delete")) {
                        sessionManager.deleteAccount()
                      },
                      secondaryButton: .cancel())
            }
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
        // Attach the specific edit profile confirmation here, or to the button itself if possible
        // To avoid conflict, let's attach it to the NavigationView content via a background modifier or similar if needed,
        // but simplest is to just chain them if they are mutually exclusive (which they are).
        // However, iOS 13/14 sometimes struggles with multiple .alerts on the same view.
        // Best practice: Attach to the button that triggers it or different parts of the hierarchy.
        
        // Let's attach this one to the ZStack (Banner) inside the ScrollView for "Edit Profile" logic
    }

    // iOS 13 compatible grid helper
    func chunkedPosts() -> [[Post]] {
        var chunks: [[Post]] = []
        let columnCount = 3
        for i in stride(from: 0, to: userPosts.count, by: columnCount) {
            let end = min(i + columnCount, userPosts.count)
            let chunk = Array(userPosts[i..<end])
            chunks.append(chunk)
        }
        return chunks
    }
}

// Extension to make it cleaner
extension View {
    func editProfileAlert(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(
                 title: Text("Edit Profile"),
                 message: Text("This will cost 32 coins. Proceed?"),
                 primaryButton: .default(Text("Start Editing"), action: onConfirm),
                 secondaryButton: .cancel()
             )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(sessionManager: SessionManager())
    }
}
