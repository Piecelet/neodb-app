//
//  LibraryView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI

private struct HorizontalDivider: View {
    let color: Color
    let height: CGFloat

    init(color: Color, height: CGFloat = 0.5) {
        self.color = color
        self.height = height
    }

    var body: some View {
        color
            .frame(height: height)
    }
}

struct LibraryView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LibraryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    let statusBarHeight: CGFloat = {
        if let windowScene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene
        {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }()
    let topTabBarHeight: CGFloat = 74
    let navBarHeight: CGFloat
    let tabBarHeight: CGFloat = 92

    init() {
        navBarHeight = UINavigationController().navigationBar.frame.height
    }

    // MARK: - Body
    var body: some View {
        VStack {
            // Without this, the tab bar will be transparent without any blur
            if #unavailable(iOS 17.0) {
                Text(verbatim: " ").frame(width: 0.01, height: 0.01)
            }
            GeometryReader { geometry in
                TabView(selection: $viewModel.selectedShelfType) {
                    ForEach(ShelfType.allCases, id: \.self) { type in
                        Group {
                            if #available(iOS 17.0, *) {
                                List {
                                    shelfContentView(
                                        for: type, geometry: geometry)
                                }
                                .safeAreaPadding(
                                    .top,
                                    topTabBarHeight + navBarHeight
                                        + statusBarHeight
                                )
                                .safeAreaPadding(.bottom, tabBarHeight)
                            } else {
                                List {
                                    shelfContentView(
                                        for: type, geometry: geometry)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.loadShelfItems(
                                type: type, refresh: true)
                        }
                        .tag(type)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .modifier(IgnoreSafeAreaModifier())
        .safeAreaInset(edge: .top) {
            headerView
        }
        .navigationTitle(String(localized: "library_title", table: "Library"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text(verbatim: " ").frame(width: 0.01, height: 0.01)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("library_title", tableName: "Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
            ToolbarItem(placement: .principal) {
                Text("library_title", tableName: "Library")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            viewModel.loadAllShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            categoryFilter

            TopTabBarView(
                items: ShelfType.allCases,
                selection: $viewModel.selectedShelfType
            ) {
                $0.displayNameForCategory(
                    viewModel.selectedCategory.itemCategory)
            }
            .padding(.bottom, 4)

            HorizontalDivider(
                color: .grayBackground, height: colorScheme == .dark ? 0.5 : 1)
        }
        .background(Material.bar)
        .padding(.bottom, -12)
    }

    private var categoryFilter: some View {
        ItemCategoryBarView(activeTab: $viewModel.selectedCategory)
    }

    // MARK: - Item View Components
    private func shelfItemView(item: ShelfMarkItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ItemCoverView(item: item.mark.item, size: .medium)
            itemDetails(for: item)
        }
        .overlay(alignment: .topTrailing) {
            chevronIcon
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }

    private func shelfItemView(mark: MarkSchema) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ItemCoverView(item: mark.item, size: .medium)
            itemDetails(mark: mark)
        }
        .overlay(alignment: .topTrailing) {
            chevronIcon
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }

    private func itemDetails(for item: ShelfMarkItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ItemTitleView(
                item: item.mark.item,
                mode: .title,
                size: .medium
            )

            ItemRatingView(
                item: item.mark.item, size: .small, hideRatingCount: true)

            ItemDescriptionView(
                item: item.mark.item, mode: .brief, size: .medium)

            ItemMarkView(
                markController: item.controller,
                size: .medium,
                brief: true,
                showEditButton: true
            )
        }
    }

    private func itemDetails(mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ItemTitleView(
                item: mark.item,
                mode: .title,
                size: .medium
            )

            ItemRatingView(item: mark.item, size: .small, hideRatingCount: true)

            ItemDescriptionView(item: mark.item, mode: .brief, size: .medium)
        }
    }

    private var chevronIcon: some View {
        Image(systemSymbol: .chevronRight)
            .foregroundStyle(.secondary)
            .font(.caption)
    }

    // MARK: - Shelf Content View
    @ViewBuilder
    private func shelfContentView(
        for type: ShelfType, geometry: GeometryProxy? = nil
    ) -> some View {
        if let state = viewModel.shelfStates[type] {
            if state.items.isEmpty {
                if let error = state.error {
                    EmptyStateView(
                        String(
                            localized: "library_error_title", table: "Library"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(state.detailedError ?? error)
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, (geometry?.size.height ?? 0) / 4)
                } else if !state.isLoading && !state.isRefreshing {
                    EmptyStateView(
                        String(
                            localized: "library_empty_title", table: "Library"),
                        systemImage: "books.vertical",
                        description: Text(
                            String(
                                format: String(
                                    localized: "library_empty_description",
                                    table: "Library"), type.displayName))
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, (geometry?.size.height ?? 0) / 4)
                } else {
                    shelfItemsPlaceholder()
                }
            } else {
                shelfItemsList(for: state, type: type)
            }
        }
    }

    //    @ViewBuilder
    //    private func emptyStateView(for state: ShelfItemsState, type: ShelfType) -> some View {
    //        if let error = state.error {
    //            EmptyStateView(
    //                String(localized: "library_error_title", table: "Library"),
    //                systemImage: "exclamationmark.triangle",
    //                description: Text(state.detailedError ?? error)
    //            )
    //        } else if !state.isLoading && !state.isRefreshing {
    //            EmptyStateView(
    //                String(localized: "library_empty_title", table: "Library"),
    //                systemImage: "books.vertical",
    //                description: Text(String(format: String(localized: "library_empty_description", table: "Library"), type.displayName))
    //            )
    //        } else {
    //            shelfItemsPlaceholder()
    //        }
    //    }

    @ViewBuilder
    private func shelfItemsList(for state: ShelfItemsState, type: ShelfType)
        -> some View
    {
        ForEach(state.items) { item in
            Button {
                router.navigate(to: .itemDetailWithItem(item: item.mark.item))
            } label: {
                shelfItemView(item: item)
                    .onAppear {
                        if item.id == state.items.last?.id {
                            Task {
                                await viewModel.loadNextPage(type: type)
                            }
                        }
                    }
            }
            .buttonStyle(.plain)
        }

        if state.isLoading && !state.isRefreshing {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
                .listRowInsets(EdgeInsets())
        }
    }

    @ViewBuilder
    private func shelfItemsPlaceholder() -> some View {
        ForEach(PagedMarkSchema.placeholders.data) { item in
            shelfItemView(mark: item)
                .redacted(reason: .placeholder)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}

private struct IgnoreSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.ignoresSafeArea(edges: .top)
        } else {
            content
        }
    }
}
