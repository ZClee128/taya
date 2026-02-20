//
//  AgreementDetails.swift
//  taya
//
//  Created by Developer on 2025/11/15.
//

import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                
                Text("Last Updated: January 15, 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("""
1. Acceptance of Terms
By downloading, installing, or using Taya ("the App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.

2. Description of Service
Taya is an astronomy education application designed to help users learn about celestial objects, document telescope observations, and explore visual content related to the night sky. The App provides curated educational content about planets, galaxies, nebulas, meteor showers, and other astronomical phenomena.

3. User Accounts
You may create an account using Sign in with Apple. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.

4. User Conduct
When using Taya, you agree to:
• Use the App only for lawful purposes
• Not upload, post, or transmit any content that is offensive, defamatory, or violates any law
• Not attempt to interfere with the proper operation of the App
• Respect intellectual property rights of others
• Report any inappropriate content or behavior you encounter

5. Content and Intellectual Property
All educational content, images, videos, and other materials provided within the App are owned by or licensed to Taya. You may not reproduce, distribute, or create derivative works from this content without prior written permission.

6. User-Generated Content
Any comments or notes you submit through the App may be reviewed and moderated. We reserve the right to remove any content that violates these terms. By submitting content, you grant Taya a non-exclusive, royalty-free license to use, display, and distribute such content within the App.

7. In-App Purchases
Certain features may require in-app purchases. All purchases are processed through Apple's App Store and are subject to Apple's terms and conditions. Refunds are handled according to Apple's refund policy.

8. Disclaimer
The App is provided "as is" without warranties of any kind. Educational content is for informational purposes only and should not be relied upon as professional scientific advice.

9. Limitation of Liability
To the maximum extent permitted by law, Taya shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App.

10. Termination
We may terminate or suspend your account at any time for violation of these Terms. Upon termination, your right to use the App will immediately cease.

11. Changes to Terms
We reserve the right to modify these Terms at any time. Continued use of the App after any changes constitutes acceptance of the modified Terms.

12. Contact Us
If you have questions about these Terms, please contact us at support@tayaapp.com.
""")
                .font(.body)
            }
            .padding()
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                
                Text("Last Updated: January 15, 2026")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("""
1. Introduction
Taya ("we", "our", or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our astronomy education application.

2. Information We Collect

a) Information from Sign in with Apple:
When you sign in, Apple may share your name and email address (or a private relay email) with us. We use this information solely to create and manage your account.

b) Usage Data:
We may collect anonymous usage statistics to improve the App experience, such as which features are used most frequently and general usage patterns.

c) User-Generated Content:
Comments and notes you create within the App are stored locally on your device and are not transmitted to our servers unless required for content moderation.

3. How We Use Your Information
• To create and maintain your account
• To provide and improve our educational content and services
• To respond to your inquiries and support requests
• To enforce our Terms of Service and Community Guidelines
• To comply with legal obligations

4. Data Storage and Security
Your personal data is stored securely using industry-standard encryption. Account credentials are managed through Apple's secure authentication system. We implement appropriate technical and organizational measures to protect your data against unauthorized access, alteration, or destruction.

5. Third-Party Services
We use the following third-party services:
• Apple Sign In: For secure authentication
• Firebase: For app configuration and analytics
• Adjust: For anonymous attribution analytics

These services have their own privacy policies governing their use of your data.

6. Data Retention
We retain your personal information for as long as your account is active. If you delete your account, we will delete your personal data within 30 days, except where retention is required by law.

7. Your Rights
You have the right to:
• Access your personal data
• Correct inaccurate data
• Delete your account and associated data
• Object to processing of your data
• Export your data in a portable format

To exercise any of these rights, please contact us at privacy@tayaapp.com.

8. Children's Privacy
Taya is suitable for users of all ages interested in astronomy education. We do not knowingly collect personal information from children under 13 without parental consent. If we learn that we have collected personal data from a child under 13, we will take steps to delete such information.

9. International Data Transfers
Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy.

10. Changes to This Policy
We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the updated policy within the App with a revised "Last Updated" date.

11. Contact Us
If you have questions or concerns about this Privacy Policy, please contact us at:
Email: privacy@tayaapp.com
""")
                    .font(.body)
            }
            .padding()
        }
    }
}
