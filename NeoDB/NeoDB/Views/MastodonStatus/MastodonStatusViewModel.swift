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
    private var loadRepliesTask: Task<Void, Never>?
    
    @Published var status: MastodonStatus?
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published private(set) var replies: [MastodonStatus] = []
    @Published private(set) var hasMore = false
    @Published private(set) var isLoadingReplies = false
    private var maxId: String?
    private var currentPage = 1
    
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
            
            if !Task.isCancelled {
                isLoading = true
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
                   let cached = try? await CacheService.shared.retrieve(
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
                
                let endpoint = StatusesEndpoint.status(id: id)
                logger.debug("Fetching status with endpoint: \(String(describing: endpoint))")
                
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: MastodonStatus.self)
                
                guard !Task.isCancelled else {
                    logger.debug("Status loading cancelled after fetch")
                    return
                }
                
                status = result
                try? await CacheService.shared.cache(
                    result, forKey: cacheKey, type: MastodonStatus.self)
                
                logger.debug("Successfully loaded status")
                
                // Load replies after status is loaded
                await loadReplies(refresh: false)
                
            } catch {
                if case NetworkError.cancelled = error {
                    logger.debug("Status loading cancelled")
                    return
                }
                
                if !Task.isCancelled {
                    logger.error("Failed to load status: \(error.localizedDescription)")
                    self.error = error
                }
            }
        }
        
        await loadTask?.value
    }
    
    func loadReplies(refresh: Bool = false) async {
        guard let status = status else { return }
        
        // Prevent duplicate requests
        guard !isLoadingReplies else { return }
        
        loadRepliesTask?.cancel()
        
        loadRepliesTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            if refresh {
                maxId = nil
                replies = []
                currentPage = 1
            }
            
            isLoadingReplies = true
            defer { isLoadingReplies = false }
            
            do {
                guard !Task.isCancelled else {
                    logger.debug("Replies loading cancelled")
                    return
                }
                
                guard accountsManager.isAuthenticated else {
                    logger.error("User not authenticated")
                    throw NetworkError.unauthorized
                }
                
                let endpoint = StatusesEndpoint.context(id: status.id)
                
                let context = try await accountsManager.currentClient.fetch(
                    endpoint, type: MastodonContext.self)
                
                if !Task.isCancelled {
                    if refresh {
                        replies = context.descendants
                    } else {
                        let existingIds = Set(replies.map(\.id))
                        let uniqueNewReplies = context.descendants.filter { !existingIds.contains($0.id) }
                        replies.append(contentsOf: uniqueNewReplies)
                    }
                    hasMore = false // Context API doesn't support pagination
                    currentPage += 1
                    logger.debug("Successfully loaded \(context.descendants.count) replies")
                }
            } catch {
                if case NetworkError.cancelled = error {
                    logger.debug("Replies loading cancelled")
                    return
                }
                
                if !Task.isCancelled {
                    logger.error("Failed to load replies: \(error.localizedDescription)")
                }
            }
        }
        
        await loadRepliesTask?.value
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
        loadRepliesTask?.cancel()
        loadRepliesTask = nil
    }
}

struct MastodonContext: Codable {
    let ancestors: [MastodonStatus]
    let descendants: [MastodonStatus]
} 
