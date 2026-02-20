//
//  ContentView.swift
//  taya
//
//  Created by Developer on 2025/10/1.
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
                            Image(systemName: "sparkles")
                            Text("Explore")
                        }
                        .tag(0)

                    DiscoverView(sessionManager: sessionManager)
                        .tabItem {
                            Image(systemName: "book.fill")
                            Text("Learn")
                        }
                        .tag(1)
                    
                    IMView(sessionManager: sessionManager)
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("Notes")
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
