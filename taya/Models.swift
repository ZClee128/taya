import Foundation
import SwiftUI

// MARK: - Lifestyle Tip

struct LifestyleTip: Identifiable, Hashable, Codable {
    var id = UUID()
    let title: String
    let category: String
    let iconName: String
    let summary: String
    let detail: String
    var videoName: String?
    var imageName: String?
    var isBookmarked: Bool = false
    var isLiked: Bool = false
    var likes: Int = 0
    let date: Date
    var comments: [TipComment] = []
}

struct TipComment: Identifiable, Hashable, Codable {
    var id = UUID()
    let authorName: String
    let authorIcon: String
    let text: String
    let date: Date
}

// MARK: - Lifestyle Category

struct LifestyleCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let color: String // hex color
}

// MARK: - User Profile

struct UserProfile: Identifiable, Hashable, Codable {
    var id = UUID()
    var displayName: String
    var bio: String
    var avatarIcon: String
    var streak: Int = 0
    var totalEntries: Int = 0
    var bookmarkCount: Int = 0
}

// MARK: - Chat / IM Models

struct ChatConversation: Identifiable, Hashable, Codable {
    var id = UUID()
    let contact: UserProfile
    var lastMessage: String
    var unreadCount: Int
    var timeLabel: String
    var messages: [ChatMessage] = []
}

struct ChatMessage: Identifiable, Hashable, Codable {
    var id = UUID()
    let content: String
    let isFromMe: Bool
    let timestamp: Date
}

// MARK: - Legacy Type Aliases

typealias User = UserProfile
extension UserProfile {
    var username: String { displayName }
    var avatarName: String { avatarIcon }
    var bannerName: String? { nil }
    var badges: [String] { [] }

    init(username: String, bio: String, avatarName: String, bannerName: String? = nil, badges: [String] = []) {
        self.init(displayName: username, bio: bio, avatarIcon: avatarName)
    }
}

typealias Post = LifestyleTip
extension LifestyleTip {
    var user: UserProfile { UserProfile(displayName: "Taya", bio: "", avatarIcon: "leaf.fill") }
    var description: String { summary }
    var categoryName: String? { category }
}

typealias Conversation = ChatConversation
typealias Message = ChatMessage

// MARK: - Sample Data

enum SampleData {

    static let currentUser = UserProfile(
        displayName: "Wellness Seeker",
        bio: "Living my best life, one day at a time 🌱",
        avatarIcon: "person.circle.fill",
        streak: 7,
        totalEntries: 42,
        bookmarkCount: 12
    )

    static let categories = [
        LifestyleCategory(name: "Recipes", iconName: "fork.knife", color: "#FF6B6B"),
        LifestyleCategory(name: "Fitness", iconName: "figure.run", color: "#4ECDC4"),
        LifestyleCategory(name: "Mindfulness", iconName: "brain.head.profile", color: "#A78BFA"),
        LifestyleCategory(name: "Sleep", iconName: "moon.zzz.fill", color: "#6366F1"),
        LifestyleCategory(name: "Nutrition", iconName: "leaf.fill", color: "#10B981"),
        LifestyleCategory(name: "Self-Care", iconName: "heart.fill", color: "#F472B6")
    ]

    static let tips: [LifestyleTip] = [
        LifestyleTip(
            title: "Morning Sunrise Stretch Routine",
            category: "Fitness",
            iconName: "figure.cooldown",
            summary: "Start your day with this gentle 10-minute stretch routine to boost energy and flexibility.",
            detail: "Begin with deep breathing for 2 minutes. Then move through cat-cow stretches, forward fold, and gentle twists. Finish with sun salutations to get your blood flowing. This routine is perfect for all fitness levels and can be done in your bedroom.",
            videoName: "sky",
            imageName: "sky",
            likes: 234,
            date: Date(),
            comments: [
                TipComment(authorName: "MorningPerson", authorIcon: "sun.max.fill", text: "This changed my mornings!", date: Date().addingTimeInterval(-600)),
                TipComment(authorName: "YogaFan", authorIcon: "figure.mind.and.body", text: "Love the sun salutations part 🧘", date: Date().addingTimeInterval(-300))
            ]
        ),
        LifestyleTip(
            title: "Starlight Meditation Guide",
            category: "Mindfulness",
            iconName: "sparkles",
            summary: "A calming evening meditation to help you unwind and prepare for restful sleep.",
            detail: "Find a comfortable position. Close your eyes and imagine a sky full of stars. Each star represents a thought. Watch them gently drift across your mind without holding onto any of them. Focus on your breathing — in for 4 counts, hold for 4, out for 6. Continue for 15 minutes.",
            videoName: "star",
            imageName: "star",
            likes: 189,
            date: Date().addingTimeInterval(-3600),
            comments: [
                TipComment(authorName: "Dreamer", authorIcon: "moon.stars.fill", text: "Best meditation ever!", date: Date().addingTimeInterval(-1800))
            ]
        ),
        LifestyleTip(
            title: "Green Goddess Smoothie Bowl",
            category: "Recipes",
            iconName: "cup.and.saucer.fill",
            summary: "Packed with spinach, banana, and superfoods — a nutritious breakfast in 5 minutes.",
            detail: "Blend 2 cups spinach, 1 frozen banana, 1/2 avocado, 1 tbsp chia seeds, and 1 cup almond milk until smooth. Pour into a bowl and top with granola, sliced banana, and a drizzle of honey. This bowl provides iron, potassium, and healthy fats to fuel your morning.",
            likes: 312,
            date: Date().addingTimeInterval(-7200)
        ),
        LifestyleTip(
            title: "Digital Detox Weekend Plan",
            category: "Self-Care",
            iconName: "iphone.slash",
            summary: "Disconnect to reconnect — a simple guide to spending a weekend without screens.",
            detail: "Saturday: Start with a morning walk in nature. Journal your thoughts over breakfast. Spend the afternoon cooking a new recipe. End with a book by candlelight.\n\nSunday: Morning yoga session. Visit a local farmer's market. Sketch or paint in the afternoon. Evening board games with friends or family.",
            likes: 567,
            date: Date().addingTimeInterval(-14400)
        ),
        LifestyleTip(
            title: "Power Nap Science",
            category: "Sleep",
            iconName: "bed.double.fill",
            summary: "The perfect 20-minute nap to recharge without grogginess.",
            detail: "The ideal power nap is between 15-20 minutes. Set an alarm and find a quiet, dark spot. Use a sleep mask if needed. Nap between 1-3 PM for best results. Avoid napping after 4 PM as it can interfere with nighttime sleep. A short coffee before your nap (coffee nap) can boost alertness even more.",
            likes: 445,
            date: Date().addingTimeInterval(-28800)
        ),
        LifestyleTip(
            title: "Meal Prep Made Simple",
            category: "Nutrition",
            iconName: "cart.fill",
            summary: "Save time and eat healthier with this beginner-friendly weekly meal prep guide.",
            detail: "Choose 3 proteins, 3 vegetables, and 2 grains for the week. Cook everything on Sunday in batches. Store in glass containers. Mix and match throughout the week. Pro tip: freeze half for variety. Start with chicken, broccoli, sweet potato, rice, salmon, and mixed greens.",
            likes: 678,
            date: Date().addingTimeInterval(-43200)
        ),
        LifestyleTip(
            title: "Evening Gratitude Practice",
            category: "Mindfulness",
            iconName: "heart.text.square.fill",
            summary: "Write down 3 things you're grateful for each night to boost happiness.",
            detail: "Before bed, take 5 minutes to write down 3 specific things from today that you're grateful for. Be specific — not just 'family' but 'the way my daughter laughed at dinner.' Research shows this practice can increase happiness by 25% within just 2 weeks of consistent practice.",
            likes: 891,
            date: Date().addingTimeInterval(-86400)
        ),
        LifestyleTip(
            title: "HIIT in 15 Minutes",
            category: "Fitness",
            iconName: "flame.fill",
            summary: "A quick high-intensity workout you can do anywhere, no equipment needed.",
            detail: "Warm up: 2 minutes light jogging in place.\nRound 1 (3x): 30s burpees, 30s mountain climbers, 30s rest.\nRound 2 (3x): 30s jump squats, 30s high knees, 30s rest.\nCool down: 2 minutes walking and stretching.\nThis burns approximately 200 calories.",
            likes: 1024,
            date: Date().addingTimeInterval(-172800)
        )
    ]

    static let conversations: [ChatConversation] = [
        ChatConversation(
            contact: UserProfile(displayName: "Sarah", bio: "Yoga instructor", avatarIcon: "figure.mind.and.body"),
            lastMessage: "Have you tried the new meditation? 🧘‍♀️",
            unreadCount: 2,
            timeLabel: "2m ago",
            messages: [
                ChatMessage(content: "Hey! How's your wellness journey going?", isFromMe: false, timestamp: Date().addingTimeInterval(-600)),
                ChatMessage(content: "Great! I've been doing the morning stretches daily", isFromMe: true, timestamp: Date().addingTimeInterval(-300)),
                ChatMessage(content: "Have you tried the new meditation? 🧘‍♀️", isFromMe: false, timestamp: Date().addingTimeInterval(-120))
            ]
        ),
        ChatConversation(
            contact: UserProfile(displayName: "Mike", bio: "Fitness coach", avatarIcon: "figure.run"),
            lastMessage: "Let's try that HIIT workout together! 💪",
            unreadCount: 0,
            timeLabel: "1h ago",
            messages: [
                ChatMessage(content: "Ready for a workout challenge?", isFromMe: false, timestamp: Date().addingTimeInterval(-7200)),
                ChatMessage(content: "Always! What did you have in mind?", isFromMe: true, timestamp: Date().addingTimeInterval(-5400)),
                ChatMessage(content: "Let's try that HIIT workout together! 💪", isFromMe: false, timestamp: Date().addingTimeInterval(-3600))
            ]
        ),
        ChatConversation(
            contact: UserProfile(displayName: "Emma", bio: "Nutritionist", avatarIcon: "leaf.fill"),
            lastMessage: "The smoothie recipe is amazing 🥤",
            unreadCount: 1,
            timeLabel: "3h ago",
            messages: [
                ChatMessage(content: "Did you try my green smoothie recipe?", isFromMe: false, timestamp: Date().addingTimeInterval(-14400)),
                ChatMessage(content: "Yes! Added some extra chia seeds", isFromMe: true, timestamp: Date().addingTimeInterval(-12600)),
                ChatMessage(content: "The smoothie recipe is amazing 🥤", isFromMe: false, timestamp: Date().addingTimeInterval(-10800))
            ]
        )
    ]
}

// MARK: - Legacy Compatibility

typealias Category = LifestyleCategory
typealias MockData = SampleData

extension SampleData {
    static let posts = tips
}
