//
//  ContentView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 12/14/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var router = Router()
    
    var body: some View {
        TabView {
            NavigationStack(path: $router.path) {
                HomeView(authService: authService)
                    .navigationDestination(for: RouterDestination.self) { destination in
                        switch destination {
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
            
            NavigationStack(path: $router.path) {
                LibraryView(authService: authService)
                    .navigationDestination(for: RouterDestination.self) { destination in
                        switch destination {
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
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            
            NavigationStack(path: $router.path) {
                ProfileView(authService: authService)
                    .navigationDestination(for: RouterDestination.self) { destination in
                        switch destination {
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
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
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
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
