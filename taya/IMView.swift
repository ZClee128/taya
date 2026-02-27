import SwiftUI
import Combine

// MARK: - Keyboard dismiss helper for iOS 13
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// Manages chat data with persistence via UserDefaults.
class ChatManager: ObservableObject {
    static let shared = ChatManager()

    @Published var conversations: [ChatConversation] = []

    private let storageKey = "taya_chat_conversations"

    private init() {
        loadConversations()
    }

    /// Load conversations from storage, or use sample data if none saved
    func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            conversations = saved
        } else {
            conversations = SampleData.conversations
        }
    }

    /// Save current conversations to storage
    func saveConversations() {
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Add a message to a conversation
    func addMessage(to conversationId: UUID, message: ChatMessage) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].messages.append(message)
            conversations[index].lastMessage = message.content
            conversations[index].timeLabel = "Just now"
            saveConversations()
        }
    }

    /// Get messages for a conversation
    func messages(for conversationId: UUID) -> [ChatMessage] {
        conversations.first(where: { $0.id == conversationId })?.messages ?? []
    }

    /// Remove a conversation (block)
    func removeConversation(_ convoId: UUID) {
        conversations.removeAll { $0.id == convoId }
        saveConversations()
    }

    /// Reset all chat data (for account deletion)
    func resetAllData() {
        conversations = SampleData.conversations
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

// MARK: - Chat List View

/// "Chat" tab — lifestyle community messaging.
struct IMView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var chatManager = ChatManager.shared
    @State private var selectedConversation: ChatConversation? = nil
    @State private var showBlockAlert = false
    @State private var blockTarget: ChatConversation? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(chatManager.conversations) { convo in
                    Button(action: {
                        self.selectedConversation = convo
                    }) {
                        conversationRow(convo)
                    }
                    .contextMenu {
                        Button(action: {
                            blockTarget = convo
                            showBlockAlert = true
                        }) {
                            HStack {
                                Image(systemName: "flag.fill")
                                Text("Report & Block")
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Chat")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedConversation) { convo in
            ChatDetailView(conversationId: convo.id, contactName: convo.contact.displayName, contactIcon: convo.contact.avatarIcon)
        }
        .alert(isPresented: $showBlockAlert) {
            Alert(
                title: Text("Report & Block"),
                message: Text("This user will be blocked and reported. Are you sure?"),
                primaryButton: .destructive(Text("Block")) {
                    if let target = blockTarget {
                        chatManager.removeConversation(target.id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func conversationRow(_ convo: ChatConversation) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.36, green: 0.72, blue: 0.66).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: convo.contact.avatarIcon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.36, green: 0.72, blue: 0.66))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(convo.contact.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(convo.timeLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(convo.lastMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Detail View

struct ChatDetailView: View {
    let conversationId: UUID
    let contactName: String
    let contactIcon: String

    @ObservedObject var chatManager = ChatManager.shared
    @State private var newMessage = ""
    @State private var showActions = false
    @Environment(\.presentationMode) var presentationMode

    private var messages: [ChatMessage] {
        chatManager.messages(for: conversationId)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { msg in
                            chatBubble(msg)
                        }
                    }
                    .padding()
                }
                .onTapGesture {
                    hideKeyboard()
                }

                Divider()

                inputBar
            }
            .navigationBarTitle(contactName)
            .navigationBarItems(
                leading: Button("Back") { presentationMode.wrappedValue.dismiss() },
                trailing: Button(action: { showActions = true }) {
                    Image(systemName: "ellipsis.circle")
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .actionSheet(isPresented: $showActions) {
            ActionSheet(title: Text("Options"), buttons: [
                .destructive(Text("Report User")) {},
                .destructive(Text("Block User")) {
                    chatManager.removeConversation(conversationId)
                    presentationMode.wrappedValue.dismiss()
                },
                .cancel()
            ])
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Type a message...", text: $newMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(newMessage.isEmpty ? .secondary : Color(red: 0.36, green: 0.72, blue: 0.66))
            }
            .disabled(newMessage.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private func chatBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isFromMe { Spacer() }

            VStack(alignment: msg.isFromMe ? .trailing : .leading, spacing: 2) {
                Text(msg.content)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(msg.isFromMe
                        ? Color(red: 0.36, green: 0.72, blue: 0.66)
                        : Color(UIColor.secondarySystemGroupedBackground))
                    .foregroundColor(msg.isFromMe ? .white : .primary)
                    .cornerRadius(16)

                Text(formatTime(msg.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if !msg.isFromMe { Spacer() }
        }
    }

    private func sendMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let msg = ChatMessage(content: text, isFromMe: true, timestamp: Date())
        chatManager.addMessage(to: conversationId, message: msg)
        newMessage = ""
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
