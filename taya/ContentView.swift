import SwiftUI

/// Root view that switches between onboarding/login and the main tab interface.
struct ContentView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if sessionManager.isLoggedIn {
                mainTabView
            } else {
                AgreementView(sessionManager: sessionManager)
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(sessionManager: sessionManager)
                .tabItem {
                    Image(systemName: "sun.max.fill")
                    Text("Today")
                }
                .tag(0)

            DiscoverView(sessionManager: sessionManager)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
                .tag(1)

            IMView(sessionManager: sessionManager)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chat")
                }
                .tag(2)

            ProfileView(sessionManager: sessionManager)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Me")
                }
                .tag(3)
        }
        .accentColor(Color(red: 0.36, green: 0.72, blue: 0.66)) // Sage green
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(sessionManager: SessionManager())
    }
}
