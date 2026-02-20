//
//  SignInWithAppleButton.swift
//  taya
//
//  Created by Developer on 2025/10/5.
//

import SwiftUI
import AuthenticationServices

/// A UIViewRepresentable wrapper for ASAuthorizationAppleIDButton
/// following Apple Human Interface Guidelines
struct SignInWithAppleButton: UIViewRepresentable {
    var type: ASAuthorizationAppleIDButton.ButtonType
    var style: ASAuthorizationAppleIDButton.Style
    var onTap: () -> Void
    
    init(
        type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        style: ASAuthorizationAppleIDButton.Style = .black,
        onTap: @escaping () -> Void
    ) {
        self.type = type
        self.style = style
        self.onTap = onTap
    }
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.cornerRadius = 12
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    class Coordinator: NSObject {
        let onTap: () -> Void
        
        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }
        
        @objc func buttonTapped() {
            onTap()
        }
    }
}
