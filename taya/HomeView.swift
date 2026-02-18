//
//  HomeView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showActionSheet = false
    @State private var showReportAlert = false
    @State private var selectedPost: Post?
    @State private var feedType = 0 // 0: For You, 1: Following
    
    @State private var sortedPosts: [Post] = [] // For stability if needed, but computed property is fine for now
    @State private var postToShare: Post? // For share sheet

    // Mock stories data
    let stories = MockData.posts.prefix(8).map { $0.user }
    
    var posts: [Post] {
        let allPosts = MockData.posts.filter { !sessionManager.blockedUserIds.contains($0.user.id) }
        if feedType == 1 {
            // Mock "Following" by just taking a subset or shuffling
            return Array(allPosts.prefix(5))
        }
        return allPosts
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ... (picker) ...
                // Top Bar with Toggle
                HStack {
                    Picker("", selection: $feedType) {
                        Text("For You").tag(0)
                        Text("Following").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground))
                
                List {
                    // ... (stories) ...
                    // Stories Section
                    if feedType == 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(stories, id: \.self) { user in
                                    VStack {
                                        AvatarView(username: user.username, size: 60, avatarName: user.avatarName)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing),
                                                        lineWidth: 3
                                                    )
                                            )
                                        Text(user.username)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .frame(width: 70)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .listRowInsets(EdgeInsets()) // Remove default list padding
                        .padding(.vertical, 5)
                    }

                    ForEach(posts) { post in
                        PostCell(post: post, onAction: {
                            self.selectedPost = post
                        }, onShare: {
                            self.postToShare = post
                        })
                        .background(
                            NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                                EmptyView()
                            }
                            .opacity(0)
                        )
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle()) // Remove inset grouped style if present
            }
            .navigationBarTitle("Taya 🌌", displayMode: .inline)
            .sheet(item: $selectedPost) { post in
                ActionMenuSheet(
                    user: post.user,
                    sessionManager: sessionManager,
                    onReport: {
                        sessionManager.reportUser(post.user)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showReportAlert = true
                        }
                    },
                    onBlock: {
                        sessionManager.blockUser(post.user)
                    }
                )
            }
            .background(EmptyView().sheet(item: $postToShare) { post in
                ShareSheet(activityItems: ["Check out this post by \(post.user.username): \(post.description)"])
            })
            .alert(isPresented: $showReportAlert) {
                Alert(title: Text("Report Submitted"), message: Text("Thank you for reporting. This post will be reviewed."), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct PostCell: View {
    let post: Post
    var onAction: () -> Void
    var onShare: () -> Void // New callback
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var likeScale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                AvatarView(username: post.user.username, size: 40, avatarName: post.user.avatarName)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(post.user.username)
                            .font(.headline)
                        if post.user.badges.contains("Verified") {
                            Image(systemName: "checkmark.circle.fill") // checkmark.seal.fill is iOS 14+
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    Text("Astrophotographer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onAction) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(10)
                }
                .buttonStyle(PlainButtonStyle()) // Prevent triggering navigation
            }
            .padding(.top, 5)

            // Image/Media
            ZStack {
                // Try to load as named asset (Assets.xcassets)
                if let uiImage = UIImage(named: post.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill) // Uniform aspect ratio
                        .frame(maxWidth: .infinity)
                        .clipped() // Clip overflow
                } 
                // Try to load from bundle path (if file is loosely in project)
                else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpeg"), let uiImage = UIImage(contentsOfFile: path) {
                     Image(uiImage: uiImage)
                         .resizable()
                         .aspectRatio(4/3, contentMode: .fill)
                         .frame(maxWidth: .infinity)
                         .clipped()
                }
                else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpg"), let uiImage = UIImage(contentsOfFile: path) {
                     Image(uiImage: uiImage)
                         .resizable()
                         .aspectRatio(4/3, contentMode: .fill)
                         .frame(maxWidth: .infinity)
                         .clipped()
                }
                // Fallback to SF Symbol
                else {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: post.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    .aspectRatio(4/3, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
                
                // Video Indicator
                if post.videoName != nil {
                     Image(systemName: "play.circle.fill")
                         .font(.system(size: 50))
                         .foregroundColor(.white)
                         .shadow(radius: 5)
                }
            }
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0)) {
                    isLiked = true
                    likeScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        likeScale = 1.0
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                        isLiked.toggle()
                        likeScale = isLiked ? 1.2 : 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            likeScale = 1.0
                        }
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(isLiked ? .red : .primary)
                        .scaleEffect(likeScale)
                }
                .buttonStyle(PlainButtonStyle())

                // Comment Button (Tap falls through to cell NavigationLink)
                Image(systemName: "bubble.right")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                
                Button(action: onShare) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isBookmarked.toggle()
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 5)

            // Likes & Caption
            Text("\(post.likes + (isLiked ? 1 : 0)) likes")
                .font(.subheadline)
                .bold()

            Text(post.user.username).bold() + Text(" ") + Text(post.description)
        }
        .padding(.vertical, 10)
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(sessionManager: SessionManager())
    }
}
