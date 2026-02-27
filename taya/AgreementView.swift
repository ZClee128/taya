import SwiftUI
import Combine
import AuthenticationServices

/// Onboarding and login view with Apple Sign In and terms acceptance.
struct AgreementView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var agreedToTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.94, green: 0.97, blue: 0.95),
                    Color(red: 0.87, green: 0.93, blue: 0.92)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                Spacer()

                // Logo & Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(accentGreen.opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 42))
                            .foregroundColor(accentGreen)
                    }
                    Text("Taya")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Your Daily Lifestyle Companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Agreement Checkbox
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 8) {
                        Button(action: { agreedToTerms.toggle() }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedToTerms ? accentGreen : .secondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 0) {
                                Text("I agree to the ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Terms of Service") { showTerms = true }
                                    .font(.caption)
                                    .foregroundColor(accentGreen)
                            }
                            HStack(spacing: 0) {
                                Text("and ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Button("Privacy Policy") { showPrivacy = true }
                                    .font(.caption)
                                    .foregroundColor(accentGreen)
                            }
                        }
                    }

                    // Sign In with Apple
                    if agreedToTerms {
                        SignInWithAppleButton { sessionManager.signIn() }
                            .frame(height: 50)
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                    } else {
                        Text("Please accept the terms to continue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showTerms) {
            AgreementDetails(type: .terms)
        }
        .sheet(isPresented: $showPrivacy) {
            AgreementDetails(type: .privacy)
        }
    }
}
