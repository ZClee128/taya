import SwiftUI
import StoreKit

/// "Me" tab — user profile with lifestyle stats, coin balance, perks, and settings.
struct ProfileView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var storeManager = StoreManager.shared
    @State private var showEditProfile = false
    @State private var showStore = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showUnlockResult = false
    @State private var unlockMessage = ""

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)
    private let goldColor = Color(red: 1.0, green: 0.78, blue: 0.18)

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    profileHeader
                    activePerksSection
                    coinBalanceCard
                    spendCoinsSection
                    statsGrid
                    settingsSection
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Me")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(sessionManager: sessionManager)
        }
        .sheet(isPresented: $showStore) {
            StoreView(sessionManager: sessionManager)
        }
        .sheet(isPresented: $showPrivacy) {
            AgreementDetails(type: .privacy)
        }
        .sheet(isPresented: $showTerms) {
            AgreementDetails(type: .terms)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Account"),
                message: Text("This will permanently delete your account and all data including coins, perks, and profile. This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    sessionManager.deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Profile Header (with VIP badge & boost indicator)

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(accentGreen.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: sessionManager.currentUser.avatarIcon)
                        .font(.system(size: 36))
                        .foregroundColor(accentGreen)
                }

                // VIP badge on avatar
                if storeManager.isVIP {
                    ZStack {
                        Circle()
                            .fill(goldColor)
                            .frame(width: 26, height: 26)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }

            // Name with VIP label
            HStack(spacing: 6) {
                Text(sessionManager.currentUser.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                if storeManager.isVIP {
                    Text("VIP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(goldColor)
                        .cornerRadius(4)
                }
            }

            // Boost indicator
            if storeManager.isProfileBoosted {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text("Profile Boosted")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            }

            Text(sessionManager.currentUser.bio)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: { showEditProfile = true }) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(accentGreen)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(accentGreen, lineWidth: 1.5)
                    )
            }
        }
        .padding(.top, 10)
    }

    // MARK: - Active Perks (shows only when perks are purchased)

    private var activePerksSection: some View {
        Group {
            if storeManager.isVIP || storeManager.isProfileBoosted || storeManager.premiumTipsUnlocked > 0 || storeManager.giftsSent > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    Text("My Perks")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        if storeManager.isVIP {
                            perkStatusRow(icon: "crown.fill", title: "VIP Badge", status: "Active", color: goldColor)
                        }
                        if storeManager.isProfileBoosted {
                            if storeManager.isVIP { Divider().padding(.leading, 52) }
                            perkStatusRow(icon: "bolt.fill", title: "Profile Boost", status: "Active", color: .purple)
                        }
                        if storeManager.premiumTipsUnlocked > 0 {
                            if storeManager.isVIP || storeManager.isProfileBoosted { Divider().padding(.leading, 52) }
                            perkStatusRow(icon: "star.fill", title: "Premium Tips", status: "\(storeManager.premiumTipsUnlocked) unlocked", color: .orange)
                        }
                        if storeManager.giftsSent > 0 {
                            Divider().padding(.leading, 52)
                            perkStatusRow(icon: "gift.fill", title: "Gifts Sent", status: "\(storeManager.giftsSent) gifts", color: .pink)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
            }
        }
    }

    private func perkStatusRow(icon: String, title: String, status: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(status)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color)
                .cornerRadius(6)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Coin Balance Card

    private var coinBalanceCard: some View {
        Button(action: { showStore = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(goldColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(goldColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("My Coins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(storeManager.coinBalance)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Top Up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentGreen)
                .cornerRadius(20)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }

    // MARK: - Spend Coins Section

    private var spendCoinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Use Coins")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                spendRow(
                    icon: "star.fill", title: "Unlock Premium Tip",
                    subtitle: storeManager.premiumTipsUnlocked > 0 ? "\(storeManager.premiumTipsUnlocked) already unlocked" : "Get exclusive lifestyle advice",
                    cost: 10, color: .orange
                ) {
                    if storeManager.unlockPremiumTip() {
                        unlockMessage = "Premium Tip #\(storeManager.premiumTipsUnlocked) unlocked! 🌟\nCheck your Today feed for exclusive content."
                    } else {
                        unlockMessage = "Not enough coins (need 10, have \(storeManager.coinBalance)). Top up first!"
                    }
                    showUnlockResult = true
                }

                Divider().padding(.leading, 52)

                spendRow(
                    icon: "gift.fill", title: "Send a Gift",
                    subtitle: storeManager.giftsSent > 0 ? "\(storeManager.giftsSent) gifts sent so far" : "Gift coins to a community friend",
                    cost: 20, color: .pink
                ) {
                    if storeManager.sendGift() {
                        unlockMessage = "Gift #\(storeManager.giftsSent) sent! 🎁\nYour generosity has been noted."
                    } else {
                        unlockMessage = "Not enough coins (need 20, have \(storeManager.coinBalance)). Top up first!"
                    }
                    showUnlockResult = true
                }

                Divider().padding(.leading, 52)

                spendRow(
                    icon: "bolt.fill", title: storeManager.isProfileBoosted ? "Profile Boosted ✓" : "Boost Your Profile",
                    subtitle: storeManager.isProfileBoosted ? "Already active!" : "Stand out in the community for 24h",
                    cost: 50, color: .purple
                ) {
                    if storeManager.isProfileBoosted {
                        unlockMessage = "Your profile is already boosted! ⚡️"
                    } else if storeManager.purchaseBoost() {
                        unlockMessage = "Profile Boosted! ⚡️\nYou now stand out in the community."
                    } else {
                        unlockMessage = "Not enough coins (need 50, have \(storeManager.coinBalance)). Top up first!"
                    }
                    showUnlockResult = true
                }

                Divider().padding(.leading, 52)

                spendRow(
                    icon: "crown.fill", title: storeManager.isVIP ? "VIP Active 👑" : "VIP Badge",
                    subtitle: storeManager.isVIP ? "You're a VIP member!" : "Show your VIP status for 7 days",
                    cost: 100, color: goldColor
                ) {
                    if storeManager.isVIP {
                        unlockMessage = "You're already a VIP! 👑"
                    } else if storeManager.purchaseVIP() {
                        unlockMessage = "VIP Badge Activated! 👑\nYour crown badge is now visible on your profile."
                    } else {
                        unlockMessage = "Not enough coins (need 100, have \(storeManager.coinBalance)). Top up first!"
                    }
                    showUnlockResult = true
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .padding(.horizontal)
        }
        .alert(isPresented: $showUnlockResult) {
            Alert(title: Text(unlockMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func spendRow(icon: String, title: String, subtitle: String, cost: Int, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(goldColor)
                    Text("\(cost)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        HStack(spacing: 0) {
            statItem(value: "\(sessionManager.currentUser.streak)", label: "Day Streak", icon: "flame.fill", color: .orange)
            Divider().frame(height: 40)
            statItem(value: "\(sessionManager.currentUser.totalEntries)", label: "Tips Read", icon: "book.fill", color: accentGreen)
            Divider().frame(height: 40)
            statItem(value: "\(sessionManager.currentUser.bookmarkCount)", label: "Bookmarks", icon: "bookmark.fill", color: .purple)
        }
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "lock.shield.fill", title: "Privacy Policy", color: .blue) { showPrivacy = true }
            Divider().padding(.leading, 52)
            settingsRow(icon: "doc.text.fill", title: "Terms of Service", color: .green) { showTerms = true }
            Divider().padding(.leading, 52)
            settingsRow(icon: "star.fill", title: "Rate Us", color: .yellow) {
                if #available(iOS 14.0, *) {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            }
            Divider().padding(.leading, 52)
            settingsRow(icon: "trash.fill", title: "Delete Account", color: .red) { showDeleteAlert = true }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    private func settingsRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 28)
                Text(title)
                    .font(.body)
                    .foregroundColor(title == "Delete Account" ? .red : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
    }
}
