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
    @State private var isSearchActive = false
    private let logger = Logger.views.contentView

    var body: some View {
        TabView(
            selection: $router.selectedTab.onUpdate { oldTab, newTab in
                HapticService.shared.selection()
                // Track tab changes
                TelemetryService.shared.trackTabChange(to: newTab)
                // Only activate search when clicking search tab while already on search tab
                if oldTab == .search && newTab == .search {
                    isSearchActive.toggle()
                }
            }
        ) {
            // Home Tab
            NavigationStack(path: router.path(for: .home)) {
                MastodonTimelinesView()
                    .navigationDestination(for: RouterDestination.self) { destination in
                        destination.destinationView
                    }
            }
            .tabItem {
                Label(
                    String(
                        localized: "timelines_title_home", table: "Timelines"),
                    systemImage: "house.fill")
            }
            .tag(TabSection.home)

            // Search Tab
            NavigationStack(path: router.path(for: .search)) {
                SearchView()
                    .navigationDestination(for: RouterDestination.self) { destination in
                        destination.destinationView
                    }
            }
            .tabItem {
                Label(
                    String(
                        localized: "discover_search_title", table: "Discover"),
                    systemImage: "magnifyingglass")
            }
            .tag(TabSection.search)

            // Library Tab
            NavigationStack(path: router.path(for: .library)) {
                LibraryView()
                    .navigationDestination(for: RouterDestination.self) { destination in
                        destination.destinationView
                    }
            }
            .tabItem {
                Label(
                    String(localized: "library_title", table: "Library"),
                    systemImage: "books.vertical.fill")
            }
            .tag(TabSection.library)

            // Profile Tab
            NavigationStack(path: router.path(for: .profile)) {
                SettingsView()
                    .navigationDestination(for: RouterDestination.self) { destination in
                        destination.destinationView
                    }
            }
            .tabItem {
                Label(
                    String(localized: "settings_title", table: "Settings"),
                    systemImage: "gear")
            }
            .tag(TabSection.profile)
        }
        .tint(.accentColor)
        .environmentObject(router)
        .onChange(of: accountsManager.shouldShowPurchase) { shouldShow in
            logger.debug("shouldShowPurchase changed to \(shouldShow)")
            if shouldShow, !storeManager.isPlus {
                router.presentSheet(.purchase)
            }
        }
        .sheet(for: router.presentedSheet) {
            router.dismissSheet()
        }
        .whatsNewSheet()
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    ContentView()
        .environmentObject(AppAccountsManager())
        .environmentObject(StoreManager())
}
