//
//  SearchView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router
    
    var body: some View {
        searchContent
            .navigationTitle("Search")
            .onAppear {
                viewModel.accountsManager = accountsManager
                Task {
                    await viewModel.loadGallery()
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    private var searchContent: some View {
        List {
            if viewModel.searchText.isEmpty {
                if !viewModel.recentSearches.isEmpty {
                    recentSearchesSection
                }
                galleryContent
            } else {
                if !viewModel.searchText.isEmpty && viewModel.searchText.count >= viewModel.minSearchLength {
                    categoryFilterSection
                }
                
                Group {
                    switch viewModel.searchState {
                    case .idle:
                        EmptyView()
                    case .searching:
                        if viewModel.showLoading {
                            searchLoadingView
                        }
                    case .noResults:
                        searchEmptyStateView
                    case .suggestions(let items):
                        suggestionsView(items)
                    case .results(let items):
                        searchResultsView(items)
                    case .error(let error):
                        searchErrorView(error)
                    }
                }
                .animation(.default, value: viewModel.searchState)
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText, prompt: "Search books, movies, music...")
        .onSubmit(of: .search) {
            Task {
                await viewModel.confirmSearch()
            }
        }
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ItemCategory.searchable.allCases, id: \.self) { category in
                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        HStack {
                            Image(symbol: category.symbolImage)
                            Text(category.displayName)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.selectedCategory == category ?
                            category.color.opacity(0.2) :
                            Color(.systemGray6)
                        )
                        .foregroundStyle(
                            viewModel.selectedCategory == category ?
                            category.color :
                            .secondary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
    }
    
    private var recentSearchesSection: some View {
        Section {
            ForEach(viewModel.recentSearches, id: \.self) { query in
                HStack {
                    Button {
                        viewModel.searchText = query
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            Text(query)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        viewModel.removeRecentSearch(query)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if !viewModel.recentSearches.isEmpty {
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.clearRecentSearches()
                    }
                } label: {
                    Text("Clear All")
                        .font(.subheadline)
                }
            }
        } header: {
            Text("Recent Searches")
        }
    }
    
    private var galleryContent: some View {
        ForEach(viewModel.galleryItems) { gallery in
            Section(header: Text(gallery.displayTitle).textCase(.none)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(gallery.items, id: \.uuid) { item in
                            Button {
                                HapticFeedback.selection()
                                router.navigate(to: .itemDetailWithItem(item: item))
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    ItemCoverImage(url: item.coverImageUrl)
                                        .frame(width: 100, height: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text(item.displayTitle ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                        .frame(width: 100)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
            }
        }
    }
    
    private var searchLoadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }
    
    private var searchEmptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No Results Found")
                .font(.headline)
            Text("Try different keywords or check your spelling")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .listRowSeparator(.hidden)
    }
    
    private func suggestionsView(_ items: [ItemSchema]) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.uuid) { index, item in
            if index == 0 {
                // First item shows full details
                Button {
                    HapticFeedback.selection()
                    router.navigate(to: .itemDetailWithItem(item: item))
                } label: {
                    ItemRowView(item: item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .buttonStyle(.plain)
            } else {
                // Other items show only title as suggestions
                Button {
                    Task {
                        await viewModel.confirmSearch(searchText: item.displayTitle ?? item.title ?? "")
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text(item.displayTitle ?? item.title ?? "")
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func searchResultsView(_ items: [ItemSchema]) -> some View {
        ForEach(items, id: \.uuid) { item in
            Button {
                HapticFeedback.selection()
                router.navigate(to: .itemDetailWithItem(item: item))
            } label: {
                ItemRowView(item: item)
            }
            .buttonStyle(.plain)
            .onAppear {
                if item == items.last && viewModel.hasMorePages {
                    viewModel.loadMore()
                }
            }
        }
    }
    
    private func searchErrorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Something Went Wrong")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await viewModel.search()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .listRowSeparator(.hidden)
    }
}

struct ItemCoverImage: View {
    let url: URL?
    
    var body: some View {
        KFImage(url)
            .placeholder {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 128)
            .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    SearchView()
        .environmentObject(AppAccountsManager())
        .environmentObject(Router())
}

