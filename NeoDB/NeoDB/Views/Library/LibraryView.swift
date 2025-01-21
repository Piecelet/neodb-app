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
        VStack(spacing: 0) {
            categoryFilter

            ScrollView(.horizontal, showsIndicators: false) {
                shelfTypePicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }

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
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
        }
        .ignoresSafeArea(edges: .bottom)
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

            ScrollView(.horizontal, showsIndicators: false) {
                shelfTypePicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
        }
    }

    private var shelfTypePicker: some View {
        HStack(spacing: 20) {
            ForEach(ShelfType.allCases, id: \.self) { type in
                VStack(spacing: 8) {
                    Text(type.displayName)
                        .font(
                            .system(
                                size: 15,
                                weight: viewModel.selectedShelfType == type
                                    ? .semibold : .regular)
                        )
                        .foregroundStyle(
                            viewModel.selectedShelfType == type
                                ? .primary : .secondary)

                    Rectangle()
                        .fill(
                            viewModel.selectedShelfType == type
                                ? Color.accentColor : .clear
                        )
                        .frame(height: 2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        viewModel.selectedShelfType = type
                    }
                }
            }
        }
        .padding(.horizontal, 4)
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
//            Spacer()
//            chevronIcon
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func itemDetails(for mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
//            HStack(alignment: .bottom, spacing: 4) {
                Text(mark.item.displayTitle ?? mark.item.title ?? "")
                    .font(.headline)
                    .lineLimit(2)
                
                ItemRatingView(item: mark.item, size: .medium, hideRatingCount: true)
//            }
            
            ItemMarkView(mark: mark, size: .medium, brief: true)

            if !mark.tags.isEmpty {
                Text(mark.tags.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var chevronIcon: some View {
        Image(systemName: "chevron.right")
            .foregroundStyle(.secondary)
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
