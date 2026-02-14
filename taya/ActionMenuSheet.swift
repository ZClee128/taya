//
//  ActionMenuSheet.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct ActionMenuSheet: View {
    let user: User
    @ObservedObject var sessionManager: SessionManager
    var onReport: () -> Void
    var onBlock: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {

        VStack(spacing: 0) {
            Text("Options")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
            
            Divider()
            
            Button(action: {
                onBlock()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Text("Block User")
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                }
                .padding()
            }
            
            Divider()
            
            Button(action: {
                onReport()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Text("Report User/Post")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "exclamationmark.bubble")
                        .foregroundColor(.primary)
                }
                .padding()
            }
            
            Divider()
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }

}
