import Foundation
import OSLog

@MainActor
class ProfileViewModel: ObservableObject {
    private let logger = Logger.views.profile
    private var loadTask: Task<Void, Never>?
    private var loadStatusesTask: Task<Void, Never>?
    private let cacheService = CacheService.shared
    
    @Published var account: MastodonAccount?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    @Published private(set) var statuses: [MastodonStatus] = []
    @Published private(set) var hasMore = false
    @Published private(set) var isLoadingStatuses = false
    private var maxId: String?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                account = nil
                statuses = []
                maxId = nil
            }
        }
    }
    
    func loadAccount(id: String, refresh: Bool = false) async {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            logger.debug("Loading account for instance: \(accountsManager.currentAccount.instance)")
            
            if refresh {
                if !Task.isCancelled {
                    isLoading = true
                }
            } else {
                if !Task.isCancelled {
                    isLoading = true
                }
            }
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                }
            }
            
            error = nil
            
            let cacheKey = "\(accountsManager.currentAccount.instance)_account_\(id)"
            logger.debug("Using cache key: \(cacheKey)")
            
            do {
                // Only load from cache if not refreshing and account is nil
                if !refresh && account == nil,
                   let cached = try? await cacheService.retrieve(
                    forKey: cacheKey, type: MastodonAccount.self)
                {
                    if !Task.isCancelled {
                        account = cached
                        logger.debug("Loaded account from cache")
                    }
                }
                
                guard !Task.isCancelled else {
                    logger.debug("Account loading cancelled")
                    return
                }
                
                guard accountsManager.isAuthenticated else {
                    logger.error("User not authenticated")
                    throw NetworkError.unauthorized
                }
                
                let endpoint = AccountsEndpoint.accounts(id: id)
                logger.debug("Fetching account with endpoint: \(String(describing: endpoint))")
                
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: MastodonAccount.self)
                
                guard !Task.isCancelled else {
                    logger.debug("Account loading cancelled after fetch")
                    return
                }
                
                account = result
                try? await cacheService.cache(
                    result, forKey: cacheKey, type: MastodonAccount.self)
                
                logger.debug("Successfully loaded account")
                
            } catch {
                if case NetworkError.cancelled = error {
                    logger.debug("Account loading cancelled")
                    return
                }
                
                if !Task.isCancelled {
                    logger.error("Failed to load account: \(error.localizedDescription)")
                    self.error = error
                    self.showError = true
                }
            }
        }
        
        await loadTask?.value
    }
    
    func loadStatuses(refresh: Bool = false) async {
        guard let account = account else { return }
        
        guard !isLoadingStatuses else { return }
        
        loadStatusesTask?.cancel()
        
        loadStatusesTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            if refresh {
                maxId = nil
                statuses = []
            }
            
            isLoadingStatuses = true
            defer { isLoadingStatuses = false }
            
            do {
                let endpoint = AccountsEndpoint.statuses(
                    id: account.id,
                    sinceId: maxId,
                    tag: nil,
                    onlyMedia: false,
                    excludeReplies: false
                )
                
                let newStatuses = try await accountsManager.currentClient.fetch(
                    endpoint, type: [MastodonStatus].self)
                
                if !Task.isCancelled {
                    if refresh {
                        statuses = newStatuses
                    } else {
                        let existingIds = Set(statuses.map(\.id))
                        let uniqueNewStatuses = newStatuses.filter { !existingIds.contains($0.id) }
                        statuses.append(contentsOf: uniqueNewStatuses)
                    }
                    maxId = newStatuses.last?.id
                    hasMore = !newStatuses.isEmpty
                }
            } catch {
                if !Task.isCancelled {
                    logger.error("Failed to load statuses: \(error.localizedDescription)")
                }
            }
        }
        
        await loadStatusesTask?.value
    }
    
    func loadNextPage() async {
        await loadStatuses(refresh: false)
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
        loadStatusesTask?.cancel()
        loadStatusesTask = nil
    }
} 
