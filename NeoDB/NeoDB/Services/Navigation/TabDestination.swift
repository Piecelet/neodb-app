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
}

// MARK: - TabView Container
//struct MainTabView: View {
//    @EnvironmentObject private var router: Router
//    @EnvironmentObject private var accountsManager: AppAccountsManager
//    @EnvironmentObject private var storeManager: StoreManager
//    @State private var isSearchActive = false
//    private let logger = Logger.views.contentView
//
//    var body: some View {
//        TabView(
//            selection: $router.selectedTab.onUpdate { oldTab, newTab in
//                // HapticService.shared.selection()
//                // Track tab changes
//                TelemetryService.shared.trackTabChange(to: newTab)
//                // Only activate search when clicking search tab while already on search tab
//                // if oldTab == .search && newTab == .search {
//                //    isSearchActive.toggle()
//                // }
//            }
//        ) {
//            NavigationStack(path: router.path(for: .home)) {
//                MastodonTimelinesView()
//            }
//            .tabItem {
//                Label(
//                    String(
//                        localized: "timelines_title_home", table: "Timelines"),
//                    systemSymbol: .houseFill)
//            }
//            .tag(TabDestination.home)
//
//            NavigationStack(path: router.path(for: .search)) {
//                SearchView()
//            }
//            .tabItem {
//                Label(
//                    String(
//                        localized: "discover_search_title", table: "Discover"),
//                    systemSymbol: .magnifyingglass)
//            }
//            .tag(TabDestination.search)
//
//            NavigationStack(path: router.path(for: .library)) {
//                LibraryView()
//            }
//            .tabItem {
//                Label(
//                    String(localized: "library_title", table: "Library"),
//                    systemSymbol: .booksVerticalFill)
//            }
//            .tag(TabDestination.library)
//
//            NavigationStack(path: router.path(for: .profile)) {
//                SettingsView()
//            }
//            .tabItem {
//                Label(
//                    String(localized: "settings_title", table: "Settings"),
//                    systemSymbol: .gear)
//            }
//            .tag(TabDestination.profile)
//        }
//        .onChange(of: accountsManager.shouldShowPurchase) { shouldShow in
//            logger.debug("shouldShowPurchase changed to \(shouldShow)")
//            if shouldShow, !storeManager.isPlus {
//                router.presentSheet(.purchase)
//            }
//        }
//        .sheet(for: router.presentedSheet) {
//            router.dismissSheet()
//        }
//        .enableInjection()
//    }
//
//    #if DEBUG
//        @ObserveInjection var forceRedraw
//    #endif
//}
