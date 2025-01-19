//
//  StatusItemViewModel.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import Foundation
import OSLog

@MainActor
class StatusItemViewModel: ObservableObject {
    private let logger = Logger.views.status.item
    private let cacheService = CacheService()
    private var loadTask: Task<Void, Never>?
    var accountsManager: AppAccountsManager?
    
    @Published var item: ItemSchema
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(item: ItemSchema) {
        self.item = item
        loadItemIfNeeded()
    }
    
    private func loadItemIfNeeded() {
        guard item.brief == item.type else { return }
        loadItem(refresh: false)
    }
    
    func loadItem(refresh: Bool) {
        loadTask?.cancel()
        
        loadTask = Task {
            if !Task.isCancelled {
                isLoading = true
            }
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                }
            }
            
            do {
                // Try cache first if not refreshing
                if !refresh, let cached = try? await getCachedItem(id: item.id) {
                    if !Task.isCancelled {
                        item = cached
                        return
                    }
                }
                
                // Fetch from network
                let endpoint = ItemEndpoint.make(id: item.id, category: item.category)
                let result = try await accountsManager?.currentClient.fetch(endpoint, type: ItemSchema.self)
                
                if !Task.isCancelled, let result = result {
                    item = result
                    try? await cacheItem(result)
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error("Failed to load item: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getCachedItem(id: String) async throws -> ItemSchema? {
        let cacheKey = "item_\(id)"
        return try await cacheService.retrieve(forKey: cacheKey, type: ItemSchema.self)
    }
    
    private func cacheItem(_ item: ItemSchema) async throws {
        let cacheKey = "item_\(item.id)"
        try await cacheService.cache(item, forKey: cacheKey, type: ItemSchema.self)
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 
