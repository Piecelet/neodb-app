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

    // MARK: - State
    @State private var activeTab: ItemCategory.shelfAvailable = .allItems

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
                    ScrollView {
                        contentView
                    }
                    .tag(type)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .refreshable {
            await viewModel.loadShelfItems(refresh: true)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onChange(of: viewModel.selectedShelfType) { newValue in
            viewModel.changeShelfType(newValue)
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
                        .font(.system(size: 15, weight: viewModel.selectedShelfType == type ? .semibold : .regular))
                        .foregroundStyle(viewModel.selectedShelfType == type ? .primary : .secondary)
                    
                    // Selection Indicator
                    Rectangle()
                        .fill(viewModel.selectedShelfType == type ? Color.accentColor : .clear)
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
        ItemCategoryBarView(activeTab: $activeTab)
            .onChange(of: activeTab) { newValue in
                viewModel.selectedCategory = newValue
                viewModel.changeCategory(newValue)
            }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if let error = viewModel.error {
            EmptyStateView(
                "Couldn't Load Library",
                systemImage: "exclamationmark.triangle",
                description: Text(viewModel.detailedError ?? error)
            )
        } else if viewModel.shelfItems.isEmpty && !viewModel.isLoading
            && !viewModel.isRefreshing
        {
            EmptyStateView(
                "No Items Found",
                systemImage: "books.vertical",
                description: Text(
                    "Add some items to your \(viewModel.selectedShelfType.displayName.lowercased()) list"
                )
            )
        } else {
            libraryContent
        }
    }

    // MARK: - Library Content
    private var libraryContent: some View {
        Group {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.shelfItems) { mark in
                    Button {
                        router.navigate(
                            to: .itemDetailWithItem(item: mark.item))
                    } label: {
                        shelfItemView(mark: mark)
                            .onAppear {
                                if mark.id == viewModel.shelfItems.last?.id {
                                    Task {
                                        await viewModel.loadNextPage()
                                    }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.isLoading && !viewModel.isRefreshing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
        .padding(.top, -8)
    }

    // MARK: - Shelf Item View
    private func shelfItemView(mark: MarkSchema) -> some View {
        HStack(spacing: 12) {
            coverImage(for: mark)
            itemDetails(for: mark)
            Spacer()
            chevronIcon
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func coverImage(for mark: MarkSchema) -> some View {
        KFImage(mark.item.coverImageUrl)
            .placeholder {
                placeholderView
            }
            .onFailure { _ in
                placeholderView
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(2 / 3, contentMode: .fit)
            .frame(width: 60)
    }

    private func itemDetails(for mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mark.item.displayTitle ?? "")
                .font(.headline)
                .lineLimit(2)

            if let rating = mark.ratingGrade {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(rating)/10")
                }
                .font(.subheadline)
            }

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
