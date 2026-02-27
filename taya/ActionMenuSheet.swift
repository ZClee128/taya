import SwiftUI

/// Context menu action sheet with Report, Share, and Bookmark options.
struct ActionMenuSheet: View {
    var onReport: (() -> Void)?
    var onShare: (() -> Void)?
    var onBookmark: (() -> Void)?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            if let onBookmark = onBookmark {
                menuButton(icon: "bookmark", title: "Bookmark", action: onBookmark)
                Divider()
            }
            if let onShare = onShare {
                menuButton(icon: "square.and.arrow.up", title: "Share", action: onShare)
                Divider()
            }
            if let onReport = onReport {
                menuButton(icon: "flag", title: "Report", color: .red, action: onReport)
                Divider()
            }
            menuButton(icon: "xmark", title: "Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding()
    }

    private func menuButton(icon: String, title: String, color: Color = .primary, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(color)
                Spacer()
            }
            .padding()
        }
    }
}
