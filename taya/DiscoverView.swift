//
//  DiscoverView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct DiscoverView: View {
    let categories: [Category] = MockData.categories
    @ObservedObject var sessionManager: SessionManager
    
    // Simple grid layout for iOS 13 as LazyVGrid is iOS 14+
    // We group categories into pairs for rows
    var categoryPairs: [[Category]] {
        var pairs: [[Category]] = []
        for i in stride(from: 0, to: categories.count, by: 2) {
            var pair: [Category] = []
            pair.append(categories[i])
            if i + 1 < categories.count {
                pair.append(categories[i + 1])
            }
            pairs.append(pair)
        }
        return pairs
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(categoryPairs.indices, id: \.self) { index in
                        HStack(spacing: 15) {
                            ForEach(categoryPairs[index]) { category in
                                ZStack {
                                    CategoryCard(category: category)
                                    NavigationLink(destination: CategoryFeedView(category: category, sessionManager: sessionManager)) {
                                        Rectangle().fill(Color.clear)
                                    }
                                }
                            }
                            // Maintain grid alignment for odd number of items
                            if categoryPairs[index].count < 2 {
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("Discover 🔭")
        }
    }
}

struct CategoryCard: View {
    let category: Category

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(12)
                .shadow(radius: 4)

            VStack {
                Image(systemName: category.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .frame(height: 120)
    }
}

struct CategoryFeedView: View {
    let category: Category
    @ObservedObject var sessionManager: SessionManager
    
    // Filter posts by category
    var posts: [Post] {
        let filtered = MockData.posts.filter { post in
            // 1. Must not be blocked
            if sessionManager.blockedUserIds.contains(post.user.id) {
                return false
            }
            // 2. Must match category
            return post.categoryName == category.name
        }
        return filtered
    }
    
    @State private var showActionSheet = false
    @State private var showReportAlert = false
    @State private var selectedPost: Post?

    var body: some View {
        List(posts) { post in
            PostCell(post: post, onAction: {
                self.selectedPost = post
                self.showActionSheet = true
            })
            .background(
                NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                    EmptyView()
                }
                .opacity(0)
            )
        }
        .navigationBarTitle(category.name)
        .sheet(isPresented: $showActionSheet) {
            if let post = selectedPost {
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
        }
        .alert(isPresented: $showReportAlert) {
            Alert(title: Text("Report Submitted"), message: Text("Thank you for reporting. This post will be reviewed."), dismissButton: .default(Text("OK")))
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(sessionManager: SessionManager())
    }
}
