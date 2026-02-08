//
//  ContentView.swift
//  taya
//
//  Created by zclee on 2026/2/8.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var sessionManager: SessionManager
    @State private var selection = 0

    var body: some View {
        Group {
            if sessionManager.isLoggedIn {
                TabView(selection: $selection) {
                    HomeView(sessionManager: sessionManager)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
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
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Messages")
                        }
                        .tag(2)

                    ProfileView(sessionManager: sessionManager)
                        .tabItem {
                            Image(systemName: "person.circle")
                            Text("Profile")
                        }
                        .tag(3)
                }
                .accentColor(.purple)
            } else {
                AgreementView(sessionManager: sessionManager)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(sessionManager: SessionManager())
    }
}
