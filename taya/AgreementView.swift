//
//  AgreementView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct AgreementView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Image(systemName: "hand.raised.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.purple)
                
                Text("Welcome to Taya")
                    .font(.largeTitle)
                    .bold()
                
                Text("Connect with astronomy lovers around the world.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("By using Taya, you agree to our:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Button(action: { showTerms = true }) {
                            Text("Terms of Service")
                                .font(.body)
                                .foregroundColor(.primary)
                                .underline()
                        }
                        .sheet(isPresented: $showTerms) {
                            TermsView()
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Button(action: { showPrivacy = true }) {
                            Text("Privacy Policy")
                                .font(.body)
                                .foregroundColor(.primary)
                                .underline()
                        }
                        .sheet(isPresented: $showPrivacy) {
                            PrivacyView()
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Community Guidelines")
                            .font(.body)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                Button(action: {
                    sessionManager.createAccount()
                }) {
                    Text("Agree & Enter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
    }
}

struct AgreementView_Previews: PreviewProvider {
    static var previews: some View {
        AgreementView(sessionManager: SessionManager())
    }
}
