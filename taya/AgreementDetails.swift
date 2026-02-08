//
//  AgreementDetails.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                
                Text("""
1. Acceptance of Terms
By accessing and using Taya, you accept and agree to be bound by the terms and provision of this agreement.

2. User Responsibilities
You are responsible for your use of the services and for any content you provide, including compliance with applicable laws, rules, and regulations.

3. Social Interactions
Taya is a social platform. Respect other users. Harassment, hate speech, and inappropriate content are strictly prohibited and will result in account termination.

4. Content Ownership
You retain your rights to any content you submit, post or display on or through the services.

5. Termination
We may terminate or suspend your access to our services immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.
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
                
                Text("""
1. Information Collection
We collect information you provide directly to us, such as your username, bio, and content you post.

2. Use of Information
We use the information we collect to provide, maintain, and improve our services, including to facilitate social interactions.

3. Data Sharing
We do not share your personal information with third parties except as described in this policy or with your consent.

4. Security
We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access.

5. Changes to Policy
We may update this privacy policy from time to time. If we make changes, we will notify you by revising the date at the top of the policy.
""")
                    .font(.body)
            }
            .padding()
        }
    }
}
