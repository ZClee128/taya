import SwiftUI
import AVKit

/// "Today" tab — the main daily lifestyle feed.
struct HomeView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var tips = SampleData.tips
    @State private var selectedTip: LifestyleTip? = nil

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)
    private let warmCoral = Color(red: 0.96, green: 0.45, blue: 0.45)

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    greetingHeader
                    dailyQuoteCard
                    featuredVideoSection
                    tipsFeedSection
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Today")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedTip) { tip in
            PostDetailView(tip: tip)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text("Let's make today count ✨")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = sessionManager.currentUser.displayName
        if hour < 12 { return "Good Morning, \(name)" }
        if hour < 17 { return "Good Afternoon, \(name)" }
        return "Good Evening, \(name)"
    }

    // MARK: - Daily Quote

    private var dailyQuoteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(accentGreen)
                Spacer()
            }
            Text("The greatest wealth is health.")
                .font(.body)
                .italic()
                .foregroundColor(.primary)
            Text("— Virgil")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Featured Video

    private var featuredVideoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Featured")
                .font(.headline)
                .padding(.horizontal)

            if let firstVideoTip = tips.first(where: { $0.videoName != nil }) {
                Button(action: {
                    self.selectedTip = firstVideoTip
                }) {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentGreen.opacity(0.3))
                            .frame(height: 200)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstVideoTip.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(firstVideoTip.summary)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        .padding(12)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(14)

                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.white.opacity(0.9))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Tips Feed

    private var tipsFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("For You")
                .font(.headline)
                .padding(.horizontal)

            ForEach(tips) { tip in
                Button(action: {
                    self.selectedTip = tip
                }) {
                    tipCard(tip)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func tipCard(_ tip: LifestyleTip) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryColor(tip.category).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: tip.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(categoryColor(tip.category))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    HStack(spacing: 2) {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                        Text(tip.category)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                        Text("\(tip.likes)")
                            .font(.caption)
                    }
                    .foregroundColor(warmCoral)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func categoryColor(_ name: String) -> Color {
        switch name {
        case "Recipes": return Color(red: 1, green: 0.42, blue: 0.42)
        case "Fitness": return Color(red: 0.31, green: 0.80, blue: 0.77)
        case "Mindfulness": return Color(red: 0.65, green: 0.55, blue: 0.98)
        case "Sleep": return Color(red: 0.39, green: 0.40, blue: 0.95)
        case "Nutrition": return Color(red: 0.06, green: 0.73, blue: 0.51)
        case "Self-Care": return Color(red: 0.96, green: 0.45, blue: 0.71)
        default: return .gray
        }
    }
}
