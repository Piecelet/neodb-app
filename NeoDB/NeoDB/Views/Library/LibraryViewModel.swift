import Foundation
import OSLog

@MainActor
final class LibraryViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.views.library
    private let cacheService = CacheService()
    
    // MARK: - Task Management
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Published Properties
    @Published var selectedShelfType: ShelfType = .wishlist
    @Published var selectedCategory: ItemCategory?
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
            
            let cacheKey = makeCacheKey(instance: accountsManager.currentAccount.instance)
            logger.debug("Using cache key: \(cacheKey)")
            
            do {
                if !refresh && shelfItems.isEmpty,
                   let cached = try? await loadFromCache(key: cacheKey)
                {
                    await handleCachedItems(cached)
                    return
                }
                
                guard !Task.isCancelled else {
                    logger.debug("Shelf items loading cancelled")
                    return
                }
                
                let result = try await fetchItems(using: accountsManager)
                await handleFetchedItems(result, cacheKey: cacheKey)
                
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
    
    // MARK: - Private Methods
    private func updateLoadingState(refresh: Bool) {
        if !Task.isCancelled {
            if refresh {
                currentPage = 1
                isRefreshing = true
            } else {
                isLoading = true
            }
        }
    }
    
    private func makeCacheKey(instance: String) -> String {
        "\(instance)_shelf_\(selectedShelfType.rawValue)_\(selectedCategory?.rawValue ?? "all")"
    }
    
    private func loadFromCache(key: String) async throws -> PagedMarkSchema? {
        try await cacheService.retrieve(forKey: key, type: PagedMarkSchema.self)
    }
    
    private func handleCachedItems(_ cached: PagedMarkSchema) async {
        if !Task.isCancelled {
            shelfItems = cached.data
            totalPages = cached.pages
            logger.debug("Loaded \(cached.data.count) items from cache")
        }
    }
    
    private func fetchItems(using accountsManager: AppAccountsManager) async throws -> PagedMarkSchema {
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
        
        return try await accountsManager.currentClient.fetch(
            endpoint, type: PagedMarkSchema.self)
    }
    
    private func handleFetchedItems(_ result: PagedMarkSchema, cacheKey: String) async {
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
        
        try? await cacheService.cache(result, forKey: cacheKey, type: PagedMarkSchema.self)
        logger.debug("Successfully loaded \(result.data.count) items")
    }
    
    private func handleError(_ error: Error) async {
        if !Task.isCancelled {
            logger.error("Failed to load shelf items: \(error.localizedDescription)")
            self.error = "Failed to load library"
            if let networkError = error as? NetworkError {
                detailedError = networkError.localizedDescription
            }
        }
    }
} 