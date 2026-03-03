import SwiftUI
import AVKit

/// "Today" tab — the main daily lifestyle feed with mood-aware content.
struct HomeView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var tips = SampleData.tips
    @State private var selectedTip: LifestyleTip? = nil
    @State private var selectedMood: MoodType? = nil
    @State private var showBreathing = false
    @State private var challenges = SampleData.dailyChallenges
    @State private var moodAnimated: MoodType? = nil

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)
    private let warmCoral = Color(red: 0.96, green: 0.45, blue: 0.45)

    // Mood-reordered tips
    private var orderedTips: [LifestyleTip] {
        guard let mood = selectedMood, let preferred = mood.preferredCategory else {
            return tips
        }
        let prioritised = tips.filter { $0.category == preferred }
        let rest = tips.filter { $0.category != preferred }
        return prioritised + rest
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    greetingHeader
                    moodCheckInSection
                    if let mood = selectedMood, mood.needsBreathing {
                        breathingPromptCard(mood: mood)
                    }
                    dailyChallengesSection
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
        .sheet(isPresented: $showBreathing) {
            BreathingExerciseView()
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

    // MARK: - Mood Check-In

    private var moodCheckInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How are you feeling?")
                    .font(.headline)
                if selectedMood != nil {
                    Spacer()
                    Button("Clear") {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMood = nil
                        }
                    }
                    .font(.caption)
                    .foregroundColor(accentGreen)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 0) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    moodButton(mood)
                }
            }
            .padding(.horizontal)

            if let mood = selectedMood {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("Showing \(mood.preferredCategory ?? "all") content for your \(mood.label.lowercased()) mood")
                        .font(.caption)
                }
                .foregroundColor(mood.accentColor)
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func moodButton(_ mood: MoodType) -> some View {
        let isSelected = selectedMood == mood
        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                selectedMood = (selectedMood == mood) ? nil : mood
                moodAnimated = mood
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                moodAnimated = nil
            }
        }) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                    .scaleEffect(moodAnimated == mood ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: moodAnimated)
                Text(mood.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? mood.accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.accentColor.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.accentColor : Color.clear, lineWidth: 1.5)
            )
            .padding(.horizontal, 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Breathing Prompt Card

    private func breathingPromptCard(mood: MoodType) -> some View {
        Button(action: { showBreathing = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(mood.accentColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 22))
                        .foregroundColor(mood.accentColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Try a Breathing Exercise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(mood == .stressed
                         ? "A few deep breaths can calm the mind 💨"
                         : "Gentle breathing helps restore your energy 🌙")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(mood.accentColor.opacity(0.08))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(mood.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    // MARK: - Daily Challenges

    private var dailyChallengesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Challenges")
                    .font(.headline)
                Spacer()
                let completed = challenges.filter { $0.isCompleted }.count
                Text("\(completed)/\(challenges.count) done")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                        challengeCard(challenge, index: index)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func challengeCard(_ challenge: DailyChallenge, index: Int) -> some View {
        let colors: [Color] = [
            Color(red: 0.36, green: 0.72, blue: 0.66),
            Color(red: 0.95, green: 0.60, blue: 0.20),
            Color(red: 0.65, green: 0.55, blue: 0.98),
            Color(red: 0.06, green: 0.73, blue: 0.51),
            Color(red: 0.96, green: 0.45, blue: 0.71)
        ]
        let color = colors[index % colors.count]

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                challenges[index].isCompleted.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: challenge.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(challenge.isCompleted ? color : Color(UIColor.tertiarySystemFill))
                            .frame(width: 24, height: 24)
                        if challenge.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(challenge.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("+\(challenge.xpReward) XP")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .frame(width: 160, alignment: .leading)
            .background(
                challenge.isCompleted
                    ? color.opacity(0.12)
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(challenge.isCompleted ? color.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .opacity(challenge.isCompleted ? 0.75 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
            Text(selectedMood != nil ? "Curated For You" : "For You")
                .font(.headline)
                .padding(.horizontal)

            ForEach(orderedTips) { tip in
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
        case "Recipes":     return Color(red: 1, green: 0.42, blue: 0.42)
        case "Fitness":     return Color(red: 0.31, green: 0.80, blue: 0.77)
        case "Mindfulness": return Color(red: 0.65, green: 0.55, blue: 0.98)
        case "Sleep":       return Color(red: 0.39, green: 0.40, blue: 0.95)
        case "Nutrition":   return Color(red: 0.06, green: 0.73, blue: 0.51)
        case "Self-Care":   return Color(red: 0.96, green: 0.45, blue: 0.71)
        default:            return .gray
        }
    }
}
