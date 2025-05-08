
//
//  ContentView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 12/14/24.
//

import OSLog
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var router = Router()
    @StateObject private var itemRepository = ItemRepository()
    @State private var isSearchActive = false
    @Environment(\.openURL) private var openURL
    private let logger = Logger.views.contentView

    var body: some View {
        TabView(
            selection: $router.selectedTab.onUpdate { oldTab, newTab in
                // HapticService.shared.selection()
                // Track tab changes
                TelemetryService.shared.trackTabChange(to: newTab)
                // Only activate search when clicking search tab while already on search tab
                if oldTab == .discover && newTab == .discover {
                    isSearchActive.toggle()
                }
            }
        ) {
            // Home Tab
            NavigationStack(path: router.path(for: .timelines)) {
                MastodonTimelinesView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(
                    String(
                        localized: "timelines_title_home", table: "Timelines"),
                    systemImage: "house.fill")
            }
            .tag(TabDestination.timelines)

            // Search Tab
            NavigationStack(path: router.path(for: .discover)) {
                SearchView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(
                    String(
                        localized: "discover_search_title", table: "Discover"),
                    systemImage: "magnifyingglass")
            }
            .tag(TabDestination.discover)

            // Library Tab
            NavigationStack(path: router.path(for: .library)) {
                LibraryView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
                    
            }
            .tabItem {
                Label(
                    String(localized: "library_title", table: "Library"),
                    systemImage: "books.vertical.fill")
            }
            .tag(TabDestination.library)

            // Profile Tab
            NavigationStack(path: router.path(for: .profile)) {
                SettingsView()
                    .navigationDestination(for: RouterDestination.self) {
                        destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label(
                    String(localized: "settings_title", table: "Settings"),
                    systemImage: "gear")
            }
            .tag(TabDestination.profile)
        }
        .tint(.accentColor)
        .environmentObject(router)
        .environmentObject(itemRepository)
        .onChange(of: accountsManager.shouldShowPurchase) { shouldShow in
            logger.debug("shouldShowPurchase changed to \(shouldShow)")
            if shouldShow, !storeManager.isPlus {
                router.presentSheet(.purchase)
            }
        }
        .sheet(
            item: Binding(
                get: { router.sheetStack.last },
                set: { _, _ in router.dismissSheet() }
            )
        ) { sheet in
            Group {
                switch sheet {
                case .newStatus:
                    Text("New Status")  // TODO: Implement StatusEditorView
                case .editStatus(let status):
                    Text("Edit Status: \(status.id)")  // TODO: Implement StatusEditorView
                case .replyToStatus(let status):
                    StatusReplyView(status: status)
                case .addToShelf(let item, let shelfType, let detentLevel):
                    MarkView(
                        item: item, shelfType: shelfType,
                        detentLevel: detentLevel
                    )
                    .environmentObject(accountsManager)
                case .editShelfItem(let mark, let shelfType, let detentLevel):
                    MarkView(
                        item: mark.item, mark: mark, shelfType: shelfType,
                        detentLevel: detentLevel
                    )
                    .environmentObject(accountsManager)
                case .itemDetails(let item):
                    ItemDetailsSheet(item: item)
                case .purchase:
                    PurchaseView(type: .sheet)
                case .purchaseWithFeature(let feature):
                    PurchaseView(type: .sheet, scrollToFeature: feature)
                case .login:
                    NavigationStack {
                        InstanceView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(action: {
                                        accountsManager.restoreLastAuthenticatedAccount()
                                        router.dismissSheet()
                                    }) {
                                        Text("Done")
                                    }
                                }
                            }
                    }
                    .interactiveDismissDisabled()
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
                category: item.type.category ?? item.category,
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
        case .statusDetailWithStatusAndItem(let status, let item):
            MastodonStatusView(id: status.id, status: status, item: item)
        case .hashTag(let tag):
            Text("Tag: #\(tag)")  // TODO: Implement HashTagView
        case .followers(let id):
            EmptyStateView(
                String(localized: "relation_followers_in_development", table: "Timelines"),
                systemImage: "person.3.fill",
                description: Text(String(localized: "store_plus_subscription_to_get_faster_development", table: "Settings")),
                actions: {
                    Button {
                        router.navigate(to: .purchase)
                    } label: {
                        Text("store_plus_subscription_button", tableName: "Settings")
                    }
                }
            )
        case .following(let id):
            EmptyStateView(
                String(localized: "relation_following_in_development", table: "Timelines"),
                systemImage: "person.3.fill",
                description: Text(String(localized: "store_plus_subscription_to_get_faster_development", table: "Settings")),
                actions: {
                    Button {
                        router.navigate(to: .purchase)
                    } label: {
                        Text("store_plus_subscription_button", tableName: "Settings")
                    }
                }
            )
        case .galleryCategory(let galleryState):
            GalleryCategoryView(galleryState: galleryState)
        case .purchase:
            PurchaseView()
        case .purchaseWithFeature(let feature):
            PurchaseView(scrollToFeature: feature)
        }
    }
    
    private func handleURL(_ url: URL) {
        URLHandler.handleItemURL(url) { destination in
            if let destination = destination {
                router.navigate(to: destination)
            } else {
                openURL(url)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppAccountsManager())
}
