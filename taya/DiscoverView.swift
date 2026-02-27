import SwiftUI

/// "Discover" tab — browse lifestyle content by category.
struct DiscoverView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedTip: LifestyleTip? = nil
    @State private var showReport = false
    @State private var reportTarget: LifestyleTip? = nil

    private let categories = SampleData.categories
    private let allTips = SampleData.tips

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    searchBar
                    categoryGrid
                    trendingSection
                    allContentSection
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Discover")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedTip) { tip in
            PostDetailView(tip: tip)
        }
        .alert(isPresented: $showReport) {
            Alert(
                title: Text("Report Content"),
                message: Text("Are you sure you want to report this content as inappropriate?"),
                primaryButton: .destructive(Text("Report")) { reportTarget = nil },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search lifestyle tips...", text: $searchText)
                .font(.body)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { col in
                            let index = row * 3 + col
                            if index < self.categories.count {
                                self.categoryButton(self.categories[index])
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func categoryButton(_ cat: LifestyleCategory) -> some View {
        Button(action: {
            if self.selectedCategory == cat.name {
                self.selectedCategory = nil
            } else {
                self.selectedCategory = cat.name
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(hexColor(cat.color).opacity(selectedCategory == cat.name ? 0.3 : 0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: cat.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(hexColor(cat.color))
                }
                Text(cat.name)
                    .font(.caption)
                    .foregroundColor(selectedCategory == cat.name ? hexColor(cat.color) : .secondary)
                    .fontWeight(selectedCategory == cat.name ? .bold : .regular)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Trending

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trending 🔥")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(filteredTips.sorted(by: { $0.likes > $1.likes }).prefix(4)) { tip in
                        Button(action: {
                            self.selectedTip = tip
                        }) {
                            trendingCard(tip)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func trendingCard(_ tip: LifestyleTip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColorForTip(tip).opacity(0.15))
                    .frame(width: 160, height: 100)
                Image(systemName: tip.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(categoryColorForTip(tip))
            }
            Text(tip.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text("\(tip.likes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - All Content

    private var allContentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedCategory ?? "All Tips")
                    .font(.headline)
                if selectedCategory != nil {
                    Button("Clear") { self.selectedCategory = nil }
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal)

            ForEach(filteredTips) { tip in
                contentRow(tip)
            }
        }
    }

    private func contentRow(_ tip: LifestyleTip) -> some View {
        Button(action: {
            self.selectedTip = tip
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(categoryColorForTip(tip).opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: tip.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(categoryColorForTip(tip))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(tip.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "tag")
                                .font(.caption)
                            Text(tip.category)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            self.reportTarget = tip
                            self.showReport = true
                        }) {
                            Image(systemName: "flag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helpers

    private var filteredTips: [LifestyleTip] {
        var result = allTips
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private func categoryColorForTip(_ tip: LifestyleTip) -> Color {
        if let cat = categories.first(where: { $0.name == tip.category }) {
            return hexColor(cat.color)
        }
        return .gray
    }

    private func hexColor(_ hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
