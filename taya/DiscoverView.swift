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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header
                    HStack {
                        Text("Explore Collections")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    ForEach(categories) { category in
                        NavigationLink(destination: CategoryFeedView(category: category, sessionManager: sessionManager)) {
                            CategoryBannerCard(category: category)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitle("Discover 🔭", displayMode: .large)
        }
    }
}

struct CategoryBannerCard: View {
    let category: Category
    
    var gradient: LinearGradient {
        switch category.name {
        case "Planets": return LinearGradient(gradient: Gradient(colors: [Color(hex: "355C7D"), Color(hex: "6C5B7B"), Color(hex: "C06C84")]), startPoint: .topLeading, endPoint: .bottomTrailing)
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
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Abstract circles for decoration
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width - 100, y: -50)
                
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width - 50, y: 50)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: category.iconName)
                            .font(.system(size: 24))
                        Text(category.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    
                    Text("Tap to view details")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.8))
                }
                .padding(20)
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color.white.opacity(0.8))
                    .padding(20)
            }
        }
        .frame(height: 100)
    }
}

// Hex color helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
            })
            .background(
                NavigationLink(destination: PostDetailView(post: post, sessionManager: sessionManager)) {
                    EmptyView()
                }
                .opacity(0)
            )
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
