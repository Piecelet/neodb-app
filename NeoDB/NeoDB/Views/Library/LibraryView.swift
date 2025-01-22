//
//  LibraryView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI

struct LibraryView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LibraryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body
    var body: some View {
        TabView(selection: $viewModel.selectedShelfType) {
            ForEach(ShelfType.allCases, id: \.self) { type in
                Group {
                    shelfContentView(for: type)
                }
                .refreshable {
                    await viewModel.loadShelfItems(
                        type: type, refresh: true)
                }
                .tag(type)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaInset(edge: .top) {
            headerView
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
            ToolbarItem(placement: .principal) {
                Text("Library")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            // 优先加载当前选中的 shelf
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
        VStack(spacing: 0) {
            categoryFilter

            TopTabBarView(
                items: ShelfType.allCases,
                selection: $viewModel.selectedShelfType
            ) { $0.displayName }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var categoryFilter: some View {
        ItemCategoryBarView(activeTab: $viewModel.selectedCategory)
    }

    // MARK: - Shelf Content View
    @ViewBuilder
    private func shelfContentView(for type: ShelfType) -> some View {
        let state = viewModel.shelfStates[type] ?? ShelfItemsState()

        if state.items.isEmpty {
            if let error = state.error {
                EmptyStateView(
                    "Couldn't Load Library",
                    systemImage: "exclamationmark.triangle",
                    description: Text(state.detailedError ?? error)
                )
            } else if !state.isLoading && !state.isRefreshing {
                EmptyStateView(
                    "No Items Found",
                    systemImage: "books.vertical",
                    description: Text(
                        "Add some items to your \(type.displayName.lowercased()) list"
                    )
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        } else {
            ScrollView {
                shelfItemsList(for: type)
                //                    .padding(.top, 170)
            }
        }
    }

    private func shelfItemsList(for type: ShelfType) -> some View {
        let state = viewModel.shelfStates[type] ?? ShelfItemsState()

        return LazyVStack(spacing: 12) {
            ForEach(state.items) { mark in
                Button {
                    router.navigate(to: .itemDetailWithItem(item: mark.item))
                } label: {
                    shelfItemView(mark: mark)
                        .onAppear {
                            if mark.id == state.items.last?.id {
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
            }
        }
        .padding()
    }

    // MARK: - Item View Components
    private func shelfItemView(mark: MarkSchema) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ItemCoverView(item: mark.item, size: .medium)
            itemDetails(for: mark)
        }
        .overlay(alignment: .topTrailing) {
            chevronIcon
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func itemDetails(for mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mark.item.displayTitle ?? mark.item.title ?? "")
                .font(.headline)
                .lineLimit(2)

            ItemRatingView(item: mark.item, size: .small, hideRatingCount: true)

            ItemDescriptionView(item: mark.item, mode: .brief, size: .medium)

            ItemMarkView(
                mark: mark, size: .medium, brief: true, showEditButton: true)
        }
    }

    private var chevronIcon: some View {
        Image(systemSymbol: .chevronRight)
            .foregroundStyle(.secondary)
            .font(.caption)
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
