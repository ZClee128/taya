//
//  IMView.swift
//  taya
//
//  Created by Assistant on 2026/2/8.
//

import SwiftUI

struct IMView: View {
    @ObservedObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationView {
            List(sessionManager.conversations) { conversation in
                NavigationLink(destination: ChatDetailView(user: conversation.user, sessionManager: sessionManager)) {
                    HStack(spacing: 15) {
                        Image(systemName: conversation.user.avatarName)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(conversation.user.username)
                                    .font(.headline)
                                Spacer()
                                Text(conversation.time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text(conversation.lastMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                Spacer()
                                if conversation.unreadCount > 0 {
                                    Text("\(conversation.unreadCount)")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationBarTitle("Messages 💬")
        }
    }
}

struct ChatDetailView: View {
    let user: User
    @ObservedObject var sessionManager: SessionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showActionSheet = false
    @State private var showReportAlert = false
    @State private var messageText = ""
    
    var messages: [Message] {
        sessionManager.conversations.first(where: { $0.user.id == user.id })?.messages ?? []
    }
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isCurrentUser {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                } else {
                                    Text(message.content)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(15)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationBarTitle(Text(user.username))
        .navigationBarItems(trailing: Button(action: {
            showActionSheet = true
        }) {
            Image(systemName: "ellipsis")
                .foregroundColor(.primary)
                .padding()
        })
        .sheet(isPresented: $showActionSheet) {
            ActionMenuSheet(
                user: user,
                sessionManager: sessionManager,
                onReport: {
                    sessionManager.reportUser(user)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showReportAlert = true
                    }
                },
                onBlock: {
                    sessionManager.blockUser(user)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showReportAlert) {
            Alert(title: Text("Report Submitted"), message: Text("Thank you for reporting. We will investigate this user."), dismissButton: .default(Text("OK")))
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        sessionManager.sendMessage(to: user, content: messageText)
        messageText = ""
    }
}

struct IMView_Previews: PreviewProvider {
    static var previews: some View {
        IMView(sessionManager: SessionManager())
    }
}
