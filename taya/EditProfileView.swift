import SwiftUI

/// Profile editor view for updating display name and bio.
struct EditProfileView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var name: String = ""
    @State private var bio: String = ""
    @Environment(\.presentationMode) var presentationMode

    private let accentGreen = Color(red: 0.36, green: 0.72, blue: 0.66)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Photo")) {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(accentGreen.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: sessionManager.currentUser.avatarIcon)
                                .font(.system(size: 36))
                                .foregroundColor(accentGreen)
                        }
                        Spacer()
                    }
                }

                Section(header: Text("Display Name")) {
                    TextField("Your name", text: $name)
                }

                Section(header: Text("Bio")) {
                    TextField("Your bio", text: $bio)
                }
            }
            .navigationBarTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button(action: {
                    sessionManager.updateProfile(name: name, bio: bio)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .bold()
                        .foregroundColor(accentGreen)
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            name = sessionManager.currentUser.displayName
            bio = sessionManager.currentUser.bio
        }
    }
}
