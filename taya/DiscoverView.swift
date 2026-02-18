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
    @State private var searchText = ""
    
    // iOS 13 compatible grid approach
    func chunkedCategories() -> [[Category]] {
        var chunks: [[Category]] = []
        let columnCount = 2
        for i in stride(from: 0, to: filteredCategories.count, by: columnCount) {
            let end = min(i + columnCount, filteredCategories.count)
            let chunk = Array(filteredCategories[i..<end])
            chunks.append(chunk)
        }
        return chunks
    }
    
    // Mock trending posts
    var trendingPosts: [Post] {
        let posts = MockData.posts.sorted { $0.likes > $1.likes }.prefix(5).map { $0 }
        if searchText.isEmpty {
            return posts
        }
        return posts.filter { post in
            post.description.localizedCaseInsensitiveContains(searchText) ||
            post.user.username.localizedCaseInsensitiveContains(searchText) ||
            (post.categoryName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Filtered categories based on search
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Search results: posts matching search text
    var searchResults: [Post] {
        guard !searchText.isEmpty else { return [] }
        return MockData.posts.filter { post in
            // Exclude blocked users
            if sessionManager.blockedUserIds.contains(post.user.id) {
                return false
            }
            return post.description.localizedCaseInsensitiveContains(searchText) ||
                   post.user.username.localizedCaseInsensitiveContains(searchText) ||
                   (post.categoryName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search stars, planets, users...", text: $searchText)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if searchText.isEmpty {
                        // === Normal Discover View ===
                        
                        // Trending Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trending Now 🔥")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(trendingPosts) { post in
                                        NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                                            TrendingPostCard(post: post)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Categories Grid
                        VStack(alignment: .leading, spacing: 12) {
                            if #available(iOS 14.0, *) {
                                Text("Explore Collections")
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                            } else {
                                // Fallback on earlier versions
                            }
                            
                            VStack(spacing: 15) {
                                ForEach(chunkedCategories(), id: \.self) { rowCategories in
                                    HStack(spacing: 15) {
                                        ForEach(rowCategories) { category in
                                            NavigationLink(destination: CategoryFeedView(category: category, sessionManager: sessionManager)) {
                                                CategoryGridCard(category: category)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        if rowCategories.count < 2 {
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // === Search Results View ===
                        VStack(alignment: .leading, spacing: 12) {
                            // Category matches
                            if !filteredCategories.isEmpty {
                                Text("Collections")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(filteredCategories) { category in
                                            NavigationLink(destination: CategoryFeedView(category: category, sessionManager: sessionManager)) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: category.iconName)
                                                        .foregroundColor(.white)
                                                    Text(category.name)
                                                        .foregroundColor(.white)
                                                        .font(.subheadline)
                                                        .bold()
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(Color.blue.opacity(0.8))
                                                .cornerRadius(20)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Post matches
                            if !searchResults.isEmpty {
                                Text("Posts (\(searchResults.count))")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                ForEach(searchResults) { post in
                                    NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                                        SearchResultRow(post: post)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal)
                            }
                            
                            if filteredCategories.isEmpty && searchResults.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No results for \"\(searchText)\"")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Try a different keyword")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitle("Discover 🔭", displayMode: .automatic)
        }
    }
}

// MARK: - Trending Post Card

struct TrendingPostCard: View {
    let post: Post
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Try to load the image from assets or bundle
            Group {
                if let uiImage = UIImage(named: post.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpeg"), let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let path = Bundle.main.path(forResource: post.imageName, ofType: "jpg"), let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Fallback: gradient background with SF Symbol
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "2c3e50"),
                                Color(hex: "3498db")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: post.imageName)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(width: 160, height: 200)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(post.description)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                    if #available(iOS 14.0, *) {
                        Text("\(post.likes)")
                            .font(.caption2)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(10)
        }
        .frame(width: 160, height: 200)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let uiImage = UIImage(named: post.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color(hex: "2c3e50")
                        Image(systemName: post.imageName)
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(10)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.user.username)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
                Text(post.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                    if #available(iOS 14.0, *) {
                        Text("\(post.likes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        // Fallback on earlier versions
                    }
                    if let cat = post.categoryName {
                        if #available(iOS 14.0, *) {
                            Text("• \(cat)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Category Grid Card

struct CategoryGridCard: View {
    let category: Category
    
    var gradient: LinearGradient {
        switch category.name {
        case "Planets": return LinearGradient(gradient: Gradient(colors: [Color(hex: "355C7D"), Color(hex: "6C5B7B")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Galaxies": return LinearGradient(gradient: Gradient(colors: [Color(hex: "4e54c8"), Color(hex: "8f94fb")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Stars": return LinearGradient(gradient: Gradient(colors: [Color(hex: "FC466B"), Color(hex: "3F5EFB")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Nebulas": return LinearGradient(gradient: Gradient(colors: [Color(hex: "11998e"), Color(hex: "38ef7d")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Events": return LinearGradient(gradient: Gradient(colors: [Color(hex: "00b09b"), Color(hex: "96c93d")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Equipment": return LinearGradient(gradient: Gradient(colors: [Color(hex: "800080"), Color(hex: "ffc0cb")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(gradient)
                .frame(height: 120)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            
            VStack(alignment: .leading) {
                Image(systemName: category.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 5)
                
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(15)
        }
    }
}

// MARK: - Hex Color Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Category Feed View

struct CategoryFeedView: View {
    let category: Category
    @ObservedObject var sessionManager: SessionManager
    
    var posts: [Post] {
        let filtered = MockData.posts.filter { post in
            if sessionManager.blockedUserIds.contains(post.user.id) {
                return false
            }
            return post.categoryName == category.name
        }
        return filtered
    }
    
    @State private var showActionSheet = false
    @State private var showReportAlert = false
    @State private var selectedPost: Post?
    @State private var postToShare: Post?

    var body: some View {
        List(posts) { post in
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
        .navigationBarTitle(category.name)
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

// Helper to make [[Category]] Hashable for ForEach id
extension Array: Identifiable where Element: Identifiable {
    public var id: String {
        self.map { "\($0.id)" }.joined(separator: ",")
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(sessionManager: SessionManager())
    }
}
