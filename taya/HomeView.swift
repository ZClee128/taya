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
    
    var posts: [Post] {
        MockData.posts.filter { !sessionManager.blockedUserIds.contains($0.user.id) }
    }

    var body: some View {
        NavigationView {
            List(posts) { post in
                PostCell(post: post, onAction: {
                    self.selectedPost = post
                })
                .background(
                    NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                        EmptyView()
                    }
                    .opacity(0)
                )
            }
            .navigationBarTitle("Taya 🌌")
            .sheet(item: $selectedPost) { post in
                ActionMenuSheet(
                    user: post.user,
                    sessionManager: sessionManager,
                    onReport: {
                        sessionManager.reportUser(post.user)
                        // Delay slightly to allow sheet to dismiss before alert
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showReportAlert = true
                        }
                    },
                    onBlock: {
                        sessionManager.blockUser(post.user)
                    }
                )
            }
            .alert(isPresented: $showReportAlert) {
                Alert(title: Text("Report Submitted"), message: Text("Thank you for reporting. This post will be reviewed."), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct PostCell: View {
    let post: Post
    var onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AvatarView(username: post.user.username, size: 40, avatarName: post.user.avatarName)
                
                VStack(alignment: .leading) {
                    Text(post.user.username)
                        .font(.headline)
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

            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "heart")
                        .font(.system(size: 20))
                }
                Spacer()
            }
            .foregroundColor(.primary)
            .padding(.vertical, 5)

            Text("\(post.likes) likes")
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
