import SwiftUI
import AVKit

/// Detail view for a lifestyle tip.
/// Shows full content, video player (if available), comments, share, bookmark, and report.
struct PostDetailView: View {
    let tip: LifestyleTip
    @State private var isBookmarked = false
    @State private var isLiked = false
    @State private var showReport = false
    @State private var showShare = false
    @Environment(\.presentationMode) var presentationMode

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Video or Header Image
                    if let videoName = tip.videoName {
                        VideoPlayerView(videoName: videoName)
                            .frame(height: 220)
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }

                    // Title & Category
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                Text(tip.category)
                                    .font(.caption)
                            }
                                .font(.caption)
                                .foregroundColor(accentGreen)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(accentGreen.opacity(0.12))
                                .cornerRadius(8)
                            Spacer()
                            Text(formatDate(tip.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(tip.title)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(tip.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Action Bar
                    HStack(spacing: 24) {
                        Button(action: { isLiked.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .secondary)
                                Text("\(tip.likes + (isLiked ? 1 : 0))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Button(action: { isBookmarked.toggle() }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isBookmarked ? accentGreen : .secondary)
                        }
                        Button(action: { showShare = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: { showReport = true }) {
                            Image(systemName: "flag")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Full Content
                    Text(tip.detail)
                        .font(.body)
                        .lineSpacing(6)
                        .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Comments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comments (\(tip.comments.count))")
                            .font(.headline)
                            .padding(.horizontal)

                        if tip.comments.isEmpty {
                            Text("No comments yet. Be the first! 💬")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(tip.comments) { comment in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: comment.authorIcon)
                                        .font(.headline)
                                        .foregroundColor(accentGreen)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(comment.authorName)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text(comment.text)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("")
            .navigationBarItems(
                leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showReport) {
            Alert(
                title: Text("Report Content"),
                message: Text("Flag this content as inappropriate?"),
                primaryButton: .destructive(Text("Report")) {},
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(activityItems: [tip.title, tip.summary])
        }
        .onAppear {
            isBookmarked = tip.isBookmarked
            isLiked = tip.isLiked
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
