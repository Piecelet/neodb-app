//
//  ContentView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 12/14/24.
//

import SwiftUI
import OSLog

struct ContentView: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @StateObject private var router = Router()
    @State private var isSearchActive = false
    private let logger = Logger.views.contentView

    var body: some View {
        TabView(selection: $router.selectedTab.onUpdate { oldTab, newTab in
            // Only activate search when clicking search tab while already on search tab
            if oldTab == .search && newTab == .search {
                isSearchActive.toggle()
            }
        }) {
            // Home Tab
            NavigationStack(path: router.path(for: .home)) {
                TimelinesView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(String(localized: "timelines_title_home", table: "Timelines"), systemImage: "house.fill")
            }
            .tag(TabSection.home)

            // Search Tab
            NavigationStack(path: router.path(for: .search)) {
                SearchView(isSearchActive: $isSearchActive)
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(String(localized: "discover_search_title", table: "Discover"), systemImage: "magnifyingglass")
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
                Label(String(localized: "library_title", table: "Library"), systemImage: "books.vertical.fill")
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
                Label(String(localized: "settings_title", table: "Settings"), systemImage: "gear")
            }
            .tag(TabSection.profile)
        }
        .tint(.accentColor)
        .environmentObject(router)
        .onChange(of: accountsManager.shouldShowPurchase) { shouldShow in
            logger.debug("shouldShowPurchase changed to \(shouldShow)")
            if shouldShow {
                router.presentSheet(.purchase)
            }
        }
        .sheet(item: Binding(
            get: { router.sheetStack.last },
            set: { _, _ in router.dismissSheet() }
        )) { sheet in
            Group {
                switch sheet {
                case .newStatus:
                    Text("New Status")  // TODO: Implement StatusEditorView
                case .editStatus(let status):
                    Text("Edit Status: \(status.id)")  // TODO: Implement StatusEditorView
                case .replyToStatus(let status):
                    StatusReplyView(status: status)
                case .addToShelf(let item, let shelfType, let detentLevel):
                    MarkView(item: item, shelfType: shelfType, detentLevel: detentLevel)
                        .environmentObject(accountsManager)
                case .editShelfItem(let mark, let shelfType, let detentLevel):
                    MarkView(item: mark.item, mark: mark, shelfType: shelfType, detentLevel: detentLevel)
                        .environmentObject(accountsManager)
                case .itemDetails(let item):
                    ItemDetailsSheet(item: item)
                case .purchase:
                    PurchaseView(type: .sheet)
                case .login:
                    LoginView()
                        .environmentObject(accountsManager)
                }
            }
            .environmentObject(router)
        }
        .whatsNewSheet()
        .enableInjection()
    }
    
    
#if DEBUG
    @ObserveInjection var forceRedraw
#endif

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
                category: item.type.category,
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
        case .purchase:
            PurchaseView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppAccountsManager())
}
