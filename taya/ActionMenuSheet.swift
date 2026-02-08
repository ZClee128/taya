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
        NavigationView {
            List {
                Section {
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
                    }
                    
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
                    }
                }
                
                Section {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Options", displayMode: .inline)
        }
    }
}
