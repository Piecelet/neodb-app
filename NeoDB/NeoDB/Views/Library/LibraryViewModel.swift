import Foundation
import OSLog

enum LibraryState {
    case loading
    case loaded
    case error
}

@MainActor
final class LibraryViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.views.library
    private let cacheService = CacheService()
    
    // MARK: - Task Management
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Published Properties
    @Published private(set) var state: LibraryState = .loading
    @Published var selectedShelfType: ShelfType = .wishlist
    @Published var selectedCategory: ItemCategory.shelfAvailable = .allItems
    @Published var shelfItems: [MarkSchema] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published var error: String?
    @Published var detailedError: String?
    
    // MARK: - Pagination Properties
    @Published private(set) var currentPage = 1
    @Published private(set) var totalPages = 1
    
    // MARK: - Public Properties
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                shelfItems = []
            }
        }
    }
    
    // MARK: - Public Methods
    func loadShelfItems(refresh: Bool = false) async {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            logger.debug("Loading shelf items for instance: \(accountsManager.currentAccount.instance)")
            
            await updateLoadingState(refresh: refresh)
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                    isRefreshing = false
                }
            }
            
            error = nil
            detailedError = nil
            
            do {
                if !refresh && shelfItems.isEmpty,
                   let cached = try? await cacheService.retrieveLibrary(
                    key: accountsManager.currentAccount.id,
                    shelfType: selectedShelfType,
                    category: selectedCategory)
                {
                    await handleCachedItems(cached)
                    return
                }
                
                guard !Task.isCancelled else {
                    logger.debug("Shelf items loading cancelled")
                    return
                }
                
                let result = try await fetchItems(using: accountsManager)
                await handleFetchedItems(result, accountsManager: accountsManager)
                
            } catch {
                await handleError(error)
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
    
    func changeCategory(_ category: ItemCategory.shelfAvailable) {
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
    
    // MARK: - Private Methods
    private func updateLoadingState(refresh: Bool) {
        if !Task.isCancelled {
            if refresh {
                currentPage = 1
                isRefreshing = true
                state = .loading
            } else {
                isLoading = true
                if shelfItems.isEmpty {
                    state = .loading
                }
            }
        }
    }
    
    private func handleCachedItems(_ cached: PagedMarkSchema) async {
        if !Task.isCancelled {
            shelfItems = cached.data
            totalPages = cached.pages
            state = .loaded
            logger.debug("Loaded \(cached.data.count) items from cache")
            
            // Refresh in background
            Task {
                await refreshInBackground()
            }
        }
    }
    
    private func fetchItems(using accountsManager: AppAccountsManager) async throws -> PagedMarkSchema {
        guard accountsManager.isAuthenticated else {
            logger.error("User not authenticated")
            throw NetworkError.unauthorized
        }
        
        let endpoint = ShelfEndpoint.get(
            type: selectedShelfType,
            category: selectedCategory != .allItems ? selectedCategory : nil,
            page: currentPage
        )
        logger.debug("Fetching shelf items with endpoint: \(String(describing: endpoint))")
        
        return try await accountsManager.currentClient.fetch(
            endpoint, type: PagedMarkSchema.self)
    }
    
    private func handleFetchedItems(_ result: PagedMarkSchema, accountsManager: AppAccountsManager) async {
        guard !Task.isCancelled else {
            logger.debug("Shelf items loading cancelled after fetch")
            return
        }
        
        if isRefreshing {
            shelfItems = result.data
        } else {
            shelfItems.append(contentsOf: result.data)
        }
        totalPages = result.pages
        state = .loaded
        
        try? await cacheService.cacheLibrary(
            result,
            key: accountsManager.currentAccount.id,
            shelfType: selectedShelfType,
            category: selectedCategory
        )
        
        logger.debug("Successfully loaded \(result.data.count) items")
    }
    
    private func handleError(_ error: Error) async {
        if !Task.isCancelled {
            logger.error("Failed to load shelf items: \(error.localizedDescription)")
            self.error = "Failed to load library"
            if let networkError = error as? NetworkError {
                detailedError = networkError.localizedDescription
            }
            state = .error
        }
    }
    
    private func refreshInBackground() async {
        guard let accountsManager = accountsManager else { return }
        
        do {
            let result = try await fetchItems(using: accountsManager)
            try? await cacheService.cacheLibrary(
                result,
                key: accountsManager.currentAccount.id,
                shelfType: selectedShelfType,
                category: selectedCategory
            )
            
            if !Task.isCancelled {
                shelfItems = result.data
                totalPages = result.pages
            }
            
            logger.debug("Background refresh completed")
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription)")
        }
    }
} 
