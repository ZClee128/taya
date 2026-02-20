//
//  PostDetailView.swift
//  taya
//
//  Created by Developer on 2025/10/25.
//

import SwiftUI
import Combine

struct PostDetailView: View {
    let post: Post
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showActionSheet = false
    @State private var showReportAlert = false
    @State private var isPlaying = true // Control video playback
    @State private var localComments: [Comment] = []
    @State private var newCommentText = ""
    @State private var showShareSheet = false
    @State private var showCommentReportAlert = false
    @State private var showCommentReportSuccess = false
    @State private var reportedCommentUser = ""
    @ObservedObject private var keyboard = KeyboardResponder()

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // User Header
                    HStack {
                        AvatarView(username: post.user.username, size: 50, avatarName: post.user.avatarName)
                        
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
                        if Bundle.main.url(forResource: videoName, withExtension: "mp4") != nil || Bundle.main.path(forResource: videoName, ofType: "mp4") != nil {
                            VideoPlayerView(videoName: videoName, isPlaying: $isPlaying)
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                        } else {
                            Image(systemName: post.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.1))
                        }
                    } else {
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
                            ZStack {
                                Color.gray.opacity(0.1)
                                Image(systemName: post.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
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
                    
                    Divider()
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Comments")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if localComments.isEmpty {
                            Text("No comments yet. Be the first to share your thoughts!")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        } else {
                            ForEach(localComments) { comment in
                                HStack(alignment: .top, spacing: 10) {
                                    AvatarView(username: comment.user.username, size: 30, avatarName: comment.user.avatarName)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(comment.user.username)
                                                .font(.subheadline)
                                                .bold()
                                            Spacer()
                                            Text(offsetDate(comment.date))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            
                                            // Report comment button
                                            Button(action: {
                                                reportedCommentUser = comment.user.username
                                                showCommentReportAlert = true
                                            }) {
                                                Image(systemName: "flag")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Text(comment.text)
                                            .font(.body)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
            
            // Comment Input (Footer) - always visible at bottom
            VStack(spacing: 0) {
                Divider()
                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                    
                    Button(action: addComment) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
                    }
                    .disabled(newCommentText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(UIColor.systemBackground))
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationBarTitle(Text("Post"), displayMode: .inline)
        .navigationBarItems(trailing: HStack {
            Button(action: {
                showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
            }
            
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .imageScale(.large)
                    .padding(.leading, 8)
            }
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
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .background(EmptyView().sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: ["Check out this post by \(post.user.username) on Taya!"])
        })
        .alert(isPresented: $showReportAlert) {
            Alert(title: Text("Report Submitted"), message: Text("Thank you for reporting. We will review this content shortly."), dismissButton: .default(Text("OK")))
        }
        .background(EmptyView().alert(isPresented: $showCommentReportAlert) {
            Alert(
                title: Text("Report Comment"),
                message: Text("Report this comment by \(reportedCommentUser) for inappropriate content?"),
                primaryButton: .destructive(Text("Report")) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCommentReportSuccess = true
                    }
                },
                secondaryButton: .cancel()
            )
        })
        .background(EmptyView().alert(isPresented: $showCommentReportSuccess) {
            Alert(
                title: Text("Thank You"),
                message: Text("Your report has been submitted. Our team will review it shortly."),
                dismissButton: .default(Text("OK"))
            )
        })
        .onAppear {
            self.isPlaying = true
            self.localComments = post.comments.sorted(by: { $0.date < $1.date })
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
    
    func offsetDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    func addComment() {
        guard !newCommentText.isEmpty, let currentUser = sessionManager.currentUser else { return }
        let newComment = Comment(user: currentUser, text: newCommentText, date: Date())
        withAnimation {
            localComments.append(newComment)
            newCommentText = ""
        }
    }
}

struct PostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PostDetailView(post: MockData.posts[0], sessionManager: SessionManager())
    }
}

// MARK: - Keyboard Responder

final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    var cancellable: AnyCancellable?

    init() {
        self.cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .compactMap { notification -> CGFloat? in
                if notification.name == UIResponder.keyboardWillHideNotification {
                    return 0
                }
                guard let userInfo = notification.userInfo,
                      let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return endFrame.height
            }
            .assign(to: \.currentHeight, on: self)
    }
    
    deinit {
        cancellable?.cancel()
    }
}
