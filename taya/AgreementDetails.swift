import SwiftUI

/// Displays Terms of Service or Privacy Policy content.
enum AgreementType {
    case terms
    case privacy

    var title: String {
        switch self {
        case .terms: return "Terms of Service"
        case .privacy: return "Privacy Policy"
        }
    }
}

struct AgreementDetails: View {
    let type: AgreementType
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .font(.body)
                    .padding()
            }
            .navigationBarTitle(type.title)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var content: String {
        switch type {
        case .terms:
            return """
            Terms of Service

            Last Updated: February 2025

            Welcome to Taya, your daily lifestyle companion. By using our app, you agree to these Terms of Service.

            1. Acceptance of Terms
            By accessing or using Taya, you agree to be bound by these terms. If you do not agree, please do not use the app.

            2. Description of Service
            Taya provides lifestyle content including wellness tips, recipes, fitness routines, mindfulness exercises, and community features. Content is provided for informational purposes only and does not constitute medical or professional advice.

            3. User Accounts
            You may create an account using Sign In with Apple. You are responsible for maintaining the confidentiality of your account.

            4. User Conduct
            You agree to use Taya responsibly:
            • Do not post offensive, harmful, or inappropriate content
            • Do not harass other users
            • Do not use the app for any illegal purpose
            • Report any inappropriate content or behavior

            5. Content
            Lifestyle tips and articles provided in the app are for general information only. Always consult a qualified professional for medical, dietary, or fitness advice.

            6. In-App Purchases
            Taya Premium is available as an in-app purchase. All purchases are processed through Apple's App Store and are subject to Apple's terms.

            7. Privacy
            Your privacy is important to us. Please refer to our Privacy Policy for information on how we collect, use, and protect your data.

            8. Termination
            We reserve the right to suspend or terminate your account if you violate these terms.

            9. Changes to Terms
            We may update these terms from time to time. Continued use of the app constitutes acceptance of updated terms.

            10. Contact
            For questions about these terms, please contact us through the app's feedback feature.
            """

        case .privacy:
            return """
            Privacy Policy

            Last Updated: February 2025

            Taya ("we", "our", "us") is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information.

            1. Information We Collect
            • Account information (name, email via Sign In with Apple)
            • Usage data (app interactions, feature usage)
            • Device information (model, OS version)

            2. How We Use Your Information
            • To provide and improve our lifestyle content
            • To personalize your experience
            • To send relevant notifications (with your permission)
            • To process in-app purchases

            3. Data Storage
            Your personal data is stored securely. Journal entries and preferences are stored locally on your device.

            4. Third-Party Services
            We use the following third-party services:
            • Firebase (push notifications, analytics)
            • Adjust (attribution analytics)
            • Apple StoreKit (in-app purchases)

            5. Data Sharing
            We do not sell your personal information. We share data only as described in this policy and as required by law.

            6. Your Rights
            You may:
            • Access your personal data
            • Request deletion of your account
            • Opt out of push notifications
            • Control permissions (camera, photos, microphone)

            7. Children's Privacy
            Taya is not intended for children under 13. We do not knowingly collect data from children.

            8. Security
            We implement appropriate security measures to protect your data.

            9. Changes to This Policy
            We may update this policy periodically. We will notify you of significant changes.

            10. Contact Us
            For privacy inquiries, please contact us through the app's feedback feature.
            """
        }
    }
}
