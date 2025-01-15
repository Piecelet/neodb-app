//
//  LibraryView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import OSLog

@MainActor
class LibraryViewModel: ObservableObject {
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                shelfItems = []
            }
        }
    }
    
    private let cacheService = CacheService()
    private let logger = Logger.views.library
    private var loadTask: Task<Void, Never>?
    
    @Published var selectedShelfType: ShelfType = .wishlist
    @Published var shelfItems: [MarkSchema] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var detailedError: String?
    @Published var isRefreshing = false
    @Published var selectedCategory: ItemCategory?
    
    @Published var currentPage = 1
    @Published var totalPages = 1
    
    func loadShelfItems(refresh: Bool = false) async {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            logger.debug("Loading shelf items for instance: \(accountsManager.currentAccount.instance)")
            
            if refresh {
                logger.debug("Refreshing shelf items, resetting pagination")
                currentPage = 1
                if !Task.isCancelled {
                    isRefreshing = true
                }
            } else {
                if !Task.isCancelled {
                    isLoading = true
                }
            }
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                    isRefreshing = false
                }
            }
            
            error = nil
            detailedError = nil
            
            let cacheKey = "\(accountsManager.currentAccount.instance)_shelf_\(selectedShelfType.rawValue)_\(selectedCategory?.rawValue ?? "all")"
            logger.debug("Using cache key: \(cacheKey)")
            
            do {
                // Only load from cache if not refreshing and shelfItems is empty
                if !refresh && shelfItems.isEmpty,
                   let cached = try? await cacheService.retrieve(
                    forKey: cacheKey, type: PagedMarkSchema.self)
                {
                    if !Task.isCancelled {
                        shelfItems = cached.data
                        totalPages = cached.pages
                        logger.debug("Loaded \(cached.data.count) items from cache")
                    }
                }
                
                guard !Task.isCancelled else {
                    logger.debug("Shelf items loading cancelled")
                    return
                }
                
                guard accountsManager.isAuthenticated else {
                    logger.error("User not authenticated")
                    throw NetworkError.unauthorized
                }
                
                let endpoint = ShelfEndpoint.get(
                    type: selectedShelfType,
                    category: selectedCategory,
                    page: currentPage
                )
                logger.debug("Fetching shelf items with endpoint: \(String(describing: endpoint))")
                
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: PagedMarkSchema.self)
                
                guard !Task.isCancelled else {
                    logger.debug("Shelf items loading cancelled after fetch")
                    return
                }
                
                if refresh {
                    shelfItems = result.data
                } else {
                    shelfItems.append(contentsOf: result.data)
                }
                totalPages = result.pages
                
                try? await cacheService.cache(
                    result, forKey: cacheKey, type: PagedMarkSchema.self)
                
                logger.debug("Successfully loaded \(result.data.count) items")
                
            } catch {
                if !Task.isCancelled {
                    logger.error("Failed to load shelf items: \(error.localizedDescription)")
                    self.error = "Failed to load library"
                    if let networkError = error as? NetworkError {
                        detailedError = networkError.localizedDescription
                    }
                }
            }
        }
        
        await loadTask?.value
    }
    
    func loadNextPage() async {
        guard currentPage < totalPages, !isLoading else { return }
        currentPage += 1
        await loadShelfItems()
    }
    
    func changeShelfType(_ type: ShelfType) {
        selectedShelfType = type
        loadTask?.cancel()
        loadTask = Task {
            await loadShelfItems(refresh: true)
        }
    }
    
    func changeCategory(_ category: ItemCategory?) {
        selectedCategory = category
        loadTask?.cancel()
        loadTask = Task {
            await loadShelfItems(refresh: true)
        }
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
}

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    init() {
        _viewModel = StateObject(wrappedValue: LibraryViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Shelf Type Picker
            ShelfFilterView(
                selectedShelfType: $viewModel.selectedShelfType,
                selectedCategory: $viewModel.selectedCategory,
                onShelfTypeChange: viewModel.changeShelfType,
                onCategoryChange: viewModel.changeCategory
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // Content
            Group {
                if let error = viewModel.error {
                    EmptyStateView(
                        "Couldn't Load Library",
                        systemImage: "exclamationmark.triangle",
                        description: Text(viewModel.detailedError ?? error)
                    )
                    .refreshable {
                        await viewModel.loadShelfItems(refresh: true)
                    }
                } else if viewModel.shelfItems.isEmpty && !viewModel.isLoading && !viewModel.isRefreshing {
                    EmptyStateView(
                        "No Items Found",
                        systemImage: "books.vertical",
                        description: Text("Add some items to your \(viewModel.selectedShelfType.displayName.lowercased()) list")
                    )
                    .refreshable {
                        await viewModel.loadShelfItems(refresh: true)
                    }
                } else {
                    libraryContent
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private var libraryContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.shelfItems) { mark in
                    Button {
                        router.navigate(to: .itemDetailWithItem(item: mark.item))
                    } label: {
                        ShelfItemView(mark: mark)
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
        .refreshable {
            await viewModel.loadShelfItems(refresh: true)
        }
    }
}
