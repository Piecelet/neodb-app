//
//  MastodonStatusViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog

@MainActor
class MastodonStatusViewModel: ObservableObject {
    private let logger = Logger.views.status.status
    private var loadTask: Task<Void, Never>?
    private let cacheService = CacheService()
    
    @Published var status: MastodonStatus?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                status = nil
            }
        }
    }
    
    func loadStatus(id: String, refresh: Bool = false) async {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            logger.debug("Loading status for instance: \(accountsManager.currentAccount.instance)")
            
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
            
            let cacheKey = "\(accountsManager.currentAccount.instance)_status_\(id)"
            logger.debug("Using cache key: \(cacheKey)")
            
            do {
                // Only load from cache if not refreshing and status is nil
                if !refresh && status == nil,
                   let cached = try? await cacheService.retrieve(
                    forKey: cacheKey, type: MastodonStatus.self)
                {
                    if !Task.isCancelled {
                        status = cached
                        logger.debug("Loaded status from cache")
                    }
                }
                
                guard !Task.isCancelled else {
                    logger.debug("Status loading cancelled")
                    return
                }
                
                guard accountsManager.isAuthenticated else {
                    logger.error("User not authenticated")
                    throw NetworkError.unauthorized
                }
                
                let endpoint = StatusesEndpoints.status(id: id)
                logger.debug("Fetching status with endpoint: \(String(describing: endpoint))")
                
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: MastodonStatus.self)
                
                guard !Task.isCancelled else {
                    logger.debug("Status loading cancelled after fetch")
                    return
                }
                
                status = result
                try? await cacheService.cache(
                    result, forKey: cacheKey, type: MastodonStatus.self)
                
                logger.debug("Successfully loaded status")
                
            } catch {
                if case NetworkError.cancelled = error {
                    logger.debug("Status loading cancelled")
                    return
                }
                
                if !Task.isCancelled {
                    logger.error("Failed to load status: \(error.localizedDescription)")
                    self.error = error
                    self.showError = true
                }
            }
        }
        
        await loadTask?.value
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 
