//
//  PostDetailView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showActionSheet = false
    @State private var showReportAlert = false
    @State private var isPlaying = true // Control video playback

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // User Header
                    HStack {
                        Image(systemName: post.user.avatarName)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(post.user.username)
                                .font(.headline)
                            Text("Astrophotographer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // Main Image or Video
                    if let videoName = post.videoName {
                        // Check if file exists (just to double check, though VideoPlayerView handles it)
                        if Bundle.main.url(forResource: videoName, withExtension: "mp4") != nil || Bundle.main.path(forResource: videoName, ofType: "mp4") != nil {
                            VideoPlayerView(videoName: videoName, isPlaying: $isPlaying)
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                        } else {
                            // Fallback to image if video is missing
                             Image(systemName: post.imageName)
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(maxWidth: .infinity)
                                 .background(Color.black.opacity(0.1))
                        }
                    } else {
                        // Fallback to Image (Try Asset -> jpeg -> jpg -> System)
                        if let uiImage = UIImage(named: post.imageName) {
                             Image(uiImage: uiImage)
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(maxWidth: .infinity)
                        } else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpeg"), let uiImage = UIImage(contentsOfFile: path) {
                             Image(uiImage: uiImage)
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(maxWidth: .infinity)
                        } else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpg"), let uiImage = UIImage(contentsOfFile: path) {
                             Image(uiImage: uiImage)
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(maxWidth: .infinity)
                        } else {
                             Image(systemName: post.imageName)
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)
                                 .frame(maxWidth: .infinity)
                        }
                    }

                    // Actions & Description
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 20) {
                            Button(action: {}) {
                                Image(systemName: "heart")
                                    .font(.system(size: 24))
                            }
                            Spacer()
                        }
                        .foregroundColor(.primary)

                        Text("\(post.likes) likes")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(post.user.username).bold()
                            Text(post.description)
                                .font(.body)
                        }
                        
                        Text(postDateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitle(Text("Post"), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            showActionSheet = true
        }) {
            Image(systemName: "ellipsis")
                .foregroundColor(.primary)
                .padding()
        })
        .sheet(isPresented: $showActionSheet) {
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
                    // PostDetailView will be dismissed by parent reload or we can force dismiss
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showReportAlert) {
            Alert(title: Text("Report Submitted"), message: Text("Thank you for reporting. We will review this content shortly."), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            self.isPlaying = true
        }
        .onDisappear {
            self.isPlaying = false
        }
    }
    
    var postDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: post.date)
    }
}

struct PostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PostDetailView(post: MockData.posts[0], sessionManager: SessionManager())
    }
}
