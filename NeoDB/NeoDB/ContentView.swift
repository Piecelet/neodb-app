//
//  ContentView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 12/14/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @StateObject private var router = Router()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Home Tab
            NavigationStack(path: router.path(for: .home)) {
                TimelinesView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(TabSection.home)

            // Search Tab
            NavigationStack(path: router.path(for: .search)) {
                SearchView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(TabSection.search)

            // Library Tab
            NavigationStack(path: router.path(for: .library)) {
                LibraryView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            .tag(TabSection.library)

            // Profile Tab
            NavigationStack(path: router.path(for: .profile)) {
                SettingsView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(TabSection.profile)
        }
        .tint(.accentColor)
        .environmentObject(router)
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .newStatus:
                Text("New Status")  // TODO: Implement StatusEditorView
            case .editStatus(let status):
                Text("Edit Status: \(status.id)")  // TODO: Implement StatusEditorView
            case .replyToStatus(let status):
                Text("Reply to: \(status.id)")  // TODO: Implement StatusEditorView
            case .addToShelf(let item):
                MarkView(item: item)
                    .environmentObject(accountsManager)
            case .editShelfItem(let mark):
                MarkView(item: mark.item, mark: mark)
                    .environmentObject(accountsManager)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: RouterDestination)
        -> some View
    {
        switch destination {
        case .itemDetail(let id):
            ItemView(
                id: id,
                category: router.itemToLoad?.category ?? .book
            )
        case .itemDetailWithItem(let item):
            ItemView(
                id: item.id,
                category: item.category,
                item: item
            )
        case .shelfDetail(let type):
            Text("Shelf: \(type.displayName)")  // TODO: Implement ShelfDetailView
        case .userShelf(let userId, let type):
            Text("User Shelf: \(userId) - \(type.displayName)")  // TODO: Implement UserShelfView
        case .userProfile(let id):
            ProfileView(id: id)
        case .userProfileWithUser(let user):
            ProfileView(id: user.username, user: user)
        case .statusDetail(let id):
            MastodonStatusView(id: id)
        case .statusDetailWithStatus(let status):
            MastodonStatusView(id: status.id, status: status)
        case .hashTag(let tag):
            Text("Tag: #\(tag)")  // TODO: Implement HashTagView
        case .followers(let id):
            Text("Followers: \(id)")  // TODO: Implement FollowersView
        case .following(let id):
            Text("Following: \(id)")  // TODO: Implement FollowingView
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppAccountsManager())
}
