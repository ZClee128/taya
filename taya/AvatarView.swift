//
//  AvatarView.swift
//  taya
//
//  Created by Assistant on 2026/2/14.
//

import SwiftUI

struct AvatarView: View {
    let username: String
    let size: CGFloat
    let avatarName: String? // Optional override with system name if needed, or specific logic

    // Generate a consistent color based on the username
    private var backgroundColor: Color {
        let hash = username.hash
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .gray]
        let index = abs(hash) % colors.count
        return colors[index]
    }

    private var initials: String {
        let components = username.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filtered = components.filter { !$0.isEmpty }
        
        if filtered.count > 1 {
            let first = filtered.first?.first.map(String.init) ?? ""
            let last = filtered.last?.first.map(String.init) ?? ""
            return (first + last).uppercased()
        } else if let first = filtered.first {
            return String(first.prefix(2)).uppercased()
        }
        return String(username.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            AvatarView(username: "NatureLover", size: 50, avatarName: nil)
            AvatarView(username: "Stargazer", size: 50, avatarName: nil)
            AvatarView(username: "Cosmic Ray", size: 50, avatarName: nil)
        }
    }
}
