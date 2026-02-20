//
//  AgreementView.swift
//  taya
//
//  Created by Developer on 2025/10/14.
//

import SwiftUI
import AuthenticationServices

struct AgreementView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Branding
            VStack(spacing: 16) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.blue.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "sparkles")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
                .shadow(color: Color.purple.opacity(0.4), radius: 15, x: 0, y: 8)
                
                Text("Taya")
                    .font(.system(size: 36, weight: .bold))
                
                if #available(iOS 14.0, *) {
                    Text("Your Astronomy Companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                } else {
                    // Fallback on earlier versions
                }
                
                Text("Learn about the cosmos through\nstunning visual observations.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            
            Spacer()
            Spacer()
            
            // Sign In Section
            VStack(spacing: 20) {
                // Sign in with Apple Button (native, following Apple HIG)
                SignInWithAppleButton(
                    type: .signIn,
                    style: .black
                ) {
                    performAppleSignIn()
                }
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 30)
                
                // Error message
                if let error = sessionManager.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
                // Legal links
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Button(action: { showTerms = true }) {
                            Text("Terms of Service")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .sheet(isPresented: $showTerms) {
                            TermsView()
                        }
                        
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showPrivacy = true }) {
                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .sheet(isPresented: $showPrivacy) {
                            PrivacyView()
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Apple Sign In
    
    private func performAppleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        let coordinator = AppleSignInCoordinator(sessionManager: sessionManager)
        controller.delegate = coordinator
        
        // Store coordinator to prevent deallocation
        AppleSignInCoordinator.current = coordinator
        
        controller.performRequests()
    }
}

/// Coordinator to handle ASAuthorizationController delegate callbacks
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    static var current: AppleSignInCoordinator?
    
    let sessionManager: SessionManager
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        sessionManager.handleAppleSignIn(result: .success(authorization))
        AppleSignInCoordinator.current = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        sessionManager.handleAppleSignIn(result: .failure(error))
        AppleSignInCoordinator.current = nil
    }
}

struct AgreementView_Previews: PreviewProvider {
    static var previews: some View {
        AgreementView(sessionManager: SessionManager())
    }
}
