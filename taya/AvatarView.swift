import SwiftUI

/// Displays a circular avatar using SF Symbols.
struct AvatarView: View {
    let iconName: String
    var size: CGFloat = 40
    var backgroundColor: Color = Color(red: 0.36, green: 0.72, blue: 0.66).opacity(0.15)
    var foregroundColor: Color = Color(red: 0.36, green: 0.72, blue: 0.66)

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            Image(systemName: iconName)
                .font(.system(size: size * 0.45))
                .foregroundColor(foregroundColor)
        }
    }
}
