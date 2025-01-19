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
            .overlay {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
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
                galleryContent
            } else {
                searchResults
                loadingIndicator
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in
            viewModel.search()
        }
        .navigationTitle("Search")
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var galleryContent: some View {
        ForEach(viewModel.galleryItems) { gallery in
            Section(header: Text(gallery.displayTitle).textCase(.none)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(gallery.items, id: \.uuid) { item in
                            Button {
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
    
    private var searchResults: some View {
        ForEach(viewModel.items, id: \.uuid) { item in
            Button {
                router.navigate(to: .itemDetailWithItem(item: item))
            } label: {
                ItemRowView(item: item)
            }
            .buttonStyle(.plain)
            .onAppear {
                if item == viewModel.items.last {
                    viewModel.loadMore()
                }
            }
        }
    }
    
    private var loadingIndicator: some View {
        Group {
            if viewModel.isLoading && !viewModel.items.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
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
            .onFailure { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
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

