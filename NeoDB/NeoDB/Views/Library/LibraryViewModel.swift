import Foundation
import OSLog

enum LibraryState {
    case loading
    case loaded
    case error
}

struct ShelfItemsState {
    var items: [MarkSchema] = []
    var state: LibraryState = .loading
    var currentPage = 1
    var totalPages = 1
    var isLoading = false
    var isRefreshing = false
    var error: String?
    var detailedError: String?
}

@MainActor
final class LibraryViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.views.library
    private let cacheService = CacheService()
    
    // MARK: - Task Management
    private var loadTasks: [ShelfType: Task<Void, Never>] = [:]
    
    // MARK: - Published Properties
    @Published var selectedShelfType: ShelfType = .wishlist
    @Published var selectedCategory: ItemCategory.shelfAvailable = .allItems
    @Published private(set) var shelfStates: [ShelfType: ShelfItemsState] = [
        .wishlist: ShelfItemsState(),
        .progress: ShelfItemsState(),
        .complete: ShelfItemsState(),
        .dropped: ShelfItemsState()
    ]
    
    // MARK: - Public Properties
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                shelfStates = [
                    .wishlist: ShelfItemsState(),
                    .progress: ShelfItemsState(),
                    .complete: ShelfItemsState(),
                    .dropped: ShelfItemsState()
                ]
            }
        }
    }
    
    // MARK: - Computed Properties
    var currentShelfState: ShelfItemsState {
        shelfStates[selectedShelfType] ?? ShelfItemsState()
    }
    
    // MARK: - Public Methods
    func loadShelfItems(type: ShelfType, refresh: Bool = false) async {
        loadTasks[type]?.cancel()
        
        loadTasks[type] = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            logger.debug("Loading shelf items for type: \(type), instance: \(accountsManager.currentAccount.instance)")
            
            updateLoadingState(type: type, refresh: refresh)
            
            defer {
                if !Task.isCancelled {
                    updateShelfState(type: type) { state in
                        state.isLoading = false
                        state.isRefreshing = false
                    }
                }
            }
            
            updateShelfState(type: type) { state in
                state.error = nil
                state.detailedError = nil
            }
            
            // 先尝试加载缓存
            if !refresh {
                if let cached = try? await cacheService.retrieveLibrary(
                    key: accountsManager.currentAccount.id,
                    shelfType: type,
                    category: selectedCategory
                ) {
                    await handleCachedItems(cached, type: type)
                }
            }
            
            // 无论是否有缓存，都进行网络请求
            guard !Task.isCancelled else {
                logger.debug("Shelf items loading cancelled for type: \(type)")
                return
            }
            
            do {
                let result = try await fetchItems(type: type, using: accountsManager)
                await handleFetchedItems(result, type: type, accountsManager: accountsManager)
            } catch {
                // 如果网络请求失败，但有缓存数据，保持缓存数据显示
                let state = shelfStates[type] ?? ShelfItemsState()
                if state.items.isEmpty {
                    await handleError(error, type: type)
                } else {
                    logger.error("Network request failed, keeping cached data: \(error.localizedDescription)")
                }
            }
        }
        
        await loadTasks[type]?.value
    }
    
    func loadNextPage(type: ShelfType) async {
        let state = shelfStates[type] ?? ShelfItemsState()
        guard state.currentPage < state.totalPages, !state.isLoading else { return }
        
        updateShelfState(type: type) { state in
            state.currentPage += 1
        }
        await loadShelfItems(type: type)
    }
    
    func changeShelfType(_ type: ShelfType) {
        selectedShelfType = type
        let state = shelfStates[type] ?? ShelfItemsState()
        if state.items.isEmpty && state.state != .loading {
            Task {
                await loadShelfItems(type: type, refresh: true)
            }
        }
    }
    
    func changeCategory(_ category: ItemCategory.shelfAvailable) {
        selectedCategory = category
        
        // 优先加载当前 shelf type
        Task {
            await loadShelfItems(type: selectedShelfType)
            
            // 然后异步加载其他 shelf types
            await withTaskGroup(of: Void.self) { group in
                for type in ShelfType.allCases where type != selectedShelfType {
                    group.addTask {
                        await self.loadShelfItems(type: type)
                    }
                }
            }
        }
    }
    
    func cleanup() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
    }
    
    // MARK: - Private Methods
    private func updateShelfState(type: ShelfType, update: (inout ShelfItemsState) -> Void) {
        var state = shelfStates[type] ?? ShelfItemsState()
        update(&state)
        shelfStates[type] = state
    }
    
    private func updateLoadingState(type: ShelfType, refresh: Bool) {
        if !Task.isCancelled {
            updateShelfState(type: type) { state in
                if refresh {
                    state.currentPage = 1
                    state.isRefreshing = true
                    state.state = .loading
                } else {
                    state.isLoading = true
                    if state.items.isEmpty {
                        state.state = .loading
                    }
                }
            }
        }
    }
    
    private func handleCachedItems(_ cached: PagedMarkSchema, type: ShelfType) async {
        if !Task.isCancelled {
            updateShelfState(type: type) { state in
                state.items = cached.data
                state.totalPages = cached.pages
                state.state = .loaded
            }
            logger.debug("Loaded \(cached.data.count) items from cache for type: \(type)")
        }
    }
    
    private func fetchItems(type: ShelfType, using accountsManager: AppAccountsManager) async throws -> PagedMarkSchema {
        guard accountsManager.isAuthenticated else {
            logger.error("User not authenticated")
            throw NetworkError.unauthorized
        }
        
        let state = shelfStates[type] ?? ShelfItemsState()
        let endpoint = ShelfEndpoint.get(
            type: type,
            category: selectedCategory != .allItems ? selectedCategory : nil,
            page: state.currentPage
        )
        logger.debug("Fetching shelf items with endpoint: \(String(describing: endpoint))")
        
        return try await accountsManager.currentClient.fetch(
            endpoint, type: PagedMarkSchema.self)
    }
    
    private func handleFetchedItems(_ result: PagedMarkSchema, type: ShelfType, accountsManager: AppAccountsManager) async {
        guard !Task.isCancelled else {
            logger.debug("Shelf items loading cancelled after fetch for type: \(type)")
            return
        }
        
        updateShelfState(type: type) { state in
            if state.isRefreshing {
                state.items = result.data
            } else {
                state.items.append(contentsOf: result.data)
            }
            state.totalPages = result.pages
            state.state = .loaded
        }
        
        try? await cacheService.cacheLibrary(
            result,
            key: accountsManager.currentAccount.id,
            shelfType: type,
            category: selectedCategory
        )
        
        logger.debug("Successfully loaded \(result.data.count) items for type: \(type)")
    }
    
    private func handleError(_ error: Error, type: ShelfType) async {
        if !Task.isCancelled {
            logger.error("Failed to load shelf items for type \(type): \(error.localizedDescription)")
            updateShelfState(type: type) { state in
                state.error = "Failed to load library"
                if let networkError = error as? NetworkError {
                    state.detailedError = networkError.localizedDescription
                }
                state.state = .error
            }
        }
    }
} 
