//
//  AppTabView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/9/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI

enum TabDestination: String, CaseIterable {
    case home
    case search
    case library
    case profile

    var title: String {
        switch self {
        case .home:
            String(localized: "timelines_title_home", table: "Timelines")
        case .search:
            String(localized: "discover_search_title", table: "Discover")
        case .library:
            String(localized: "library_title", table: "Library")
        case .profile:
            String(localized: "settings_title", table: "Settings")
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .search: "magnifyingglass"
        case .library: "books.vertical.fill"
        case .profile: "gear"
        }
    }
}

// MARK: - View Builder
extension TabDestination {
    @ViewBuilder
    var tabContent: some View {
        mainContent
            .navigationDestination(for: RouterDestination.self) { destination in
                destination.destinationView
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch self {
        case .home:
            MastodonTimelinesView()
        case .search:
            SearchView()
        case .library:
            LibraryView()
        case .profile:
            SettingsView()
        }
    }
}

// MARK: - TabView Container
struct MainTabView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var storeManager: StoreManager
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
            ForEach(TabDestination.allCases, id: \.self) { tab in
                NavigationStack(path: router.path(for: tab)) {
                    tab.tabContent
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .onChange(of: accountsManager.shouldShowPurchase) { shouldShow in
            logger.debug("shouldShowPurchase changed to \(shouldShow)")
            if shouldShow, !storeManager.isPlus {
                router.presentSheet(.purchase)
            }
        }
        .sheet(for: router.presentedSheet) {
            router.dismissSheet()
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
