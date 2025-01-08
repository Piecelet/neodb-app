//
//  ContentView.swift
//  NeoDB
//
//  Created by citron on 12/14/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView(authService: authService)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationStack {
                Text("Search")
                    .navigationTitle("Search")
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            NavigationStack {
                LibraryView(authService: authService)
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            
            NavigationStack {
                ProfileView(authService: authService)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .tint(.accentColor)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
