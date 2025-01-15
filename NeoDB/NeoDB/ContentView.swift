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
                /* Temporarily disabled during migration
                SearchView(authService: authService)
                    .navigationDestination(for: RouterDestination.self) { destination in
                        destinationView(for: destination)
                    }
                */
                Text("Search")
                    .navigationTitle("Search")
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
                /* Temporarily disabled during migration
                LibraryView(authService: authService)
                    .navigationDestination(for: RouterDestination.self) { destination in
                        destinationView(for: destination)
                    }
                */
                Text("Library")
                    .navigationTitle("Library")
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
                ProfileView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
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
                Text("Add to Shelf: \(item.displayTitle)")  // TODO: Implement ShelfEditorView
            case .editShelfItem(let mark):
                Text("Edit Shelf Item: \(mark.item.displayTitle)")  // TODO: Implement ShelfEditorView
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: RouterDestination)
        -> some View
    {
        switch destination {
        /* Temporarily disabled during migration
        case .itemDetail(let id):
            ItemDetailViewContainer(
                itemDetailService: ItemDetailService(authService: authService, router: router),
                id: id,
                category: router.itemToLoad?.category
            )
        case .itemDetailWithItem(let item):
            ItemDetailViewContainer(
                itemDetailService: ItemDetailService(authService: authService, router: router),
                id: item.id,
                category: item.category,
                item: item
            )
        */
        case .itemDetail(let id):
            Text("Item Detail: \(id)")  // TODO: Implement ItemDetailView
        case .itemDetailWithItem(let item):
            Text("Item Detail: \(item.id)")  // TODO: Implement ItemDetailView
        case .shelfDetail(let type):
            Text("Shelf: \(type.displayName)")  // TODO: Implement ShelfDetailView
        case .userShelf(let userId, let type):
            Text("User Shelf: \(userId) - \(type.displayName)")  // TODO: Implement UserShelfView
        case .userProfile(let id):
            Text("User Profile: \(id)")  // TODO: Implement UserProfileView
        case .userProfileWithUser(let user):
            Text("User Profile: \(user.displayName)")  // TODO: Implement UserProfileView
        case .statusDetail(let id):
            Text("Status: \(id)")  // TODO: Implement StatusDetailView
        case .statusDetailWithStatus(let status):
            Text("Status: \(status.id)")  // TODO: Implement StatusDetailView
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
