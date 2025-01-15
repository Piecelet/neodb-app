//
//  ItemActionsViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog

@MainActor
class ItemActionsViewModel: ObservableObject {
    private let logger = Logger.views.itemActions
    private let cacheService = CacheService()
    let item: (any ItemProtocol)?
    private var loadTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                loadMarkIfNeeded()
            }
        }
    }
    
    var onAddToShelf: () -> Void = {}
    
    @Published var mark: MarkSchema?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showError = false
    
    init(item: (any ItemProtocol)?) {
        self.item = item
    }
    
    // MARK: - Computed Properties
    
    var state: ItemState {
        if isLoading {
            return .loading
        }
        if error != nil {
            return .error
        }
        return .loaded
    }
    
    var shareURL: URL? {
        guard let item = item,
              let accountsManager = accountsManager else { return nil }
        return ItemURL.makeShareURL(for: item, instance: accountsManager.currentAccount.instance)
    }
    
    var shelfType: ShelfType? {
        mark?.shelfType
    }
    
    var createdTime: ServerDate? {
        mark?.createdTime
    }
    
    var ratingGrade: Int? {
        mark?.ratingGrade
    }
    
    var commentText: String? {
        mark?.commentText
    }
    
    // MARK: - Public Methods
    
    func loadMarkIfNeeded() {
        guard mark == nil, let item = item else { return }
        loadMark(itemId: item.uuid, refresh: false)
    }
    
    func refresh() {
        guard let item = item else { return }
        loadMark(itemId: item.uuid, refresh: true)
    }
    
    private func loadMark(itemId: String, refresh: Bool) {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            if refresh {
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
            
            do {
                // Try cache first if not refreshing
                if !refresh, let cached = try? await getCachedMark(itemId: itemId) {
                    if !Task.isCancelled {
                        mark = cached
                    }
                }
                
                // Always fetch from network
                let endpoint = MarkEndpoint.get(itemId: itemId)
                let result = try await accountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
                
                if !Task.isCancelled {
                    mark = result
                    try? await cacheMark(result, itemId: itemId)
                }
            } catch {
                if !Task.isCancelled {
                    if let networkError = error as? NetworkError,
                       case .httpError(let statusCode) = networkError,
                       statusCode == 404 {
                        // 404 means no mark exists, which is a normal case
                        mark = nil
                        logger.debug("No mark found for item: \(itemId)")
                    } else {
                        // Only show error if we don't have cached data
                        if mark == nil {
                            self.error = error
                            self.showError = true
                            logger.error("Failed to load mark: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func getCachedMark(itemId: String) async throws -> MarkSchema? {
        let cacheKey = "mark_\(itemId)"
        return try await cacheService.retrieve(forKey: cacheKey, type: MarkSchema.self)
    }
    
    private func cacheMark(_ mark: MarkSchema, itemId: String) async throws {
        let cacheKey = "mark_\(itemId)"
        try await cacheService.cache(mark, forKey: cacheKey, type: MarkSchema.self)
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 