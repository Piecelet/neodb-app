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
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                loadItemIfNeeded()
            }
        }
    }
    
    @Published var item: any ItemProtocol {
        didSet {
            updateShowSkeleton()
        }
    }
    @Published private var isLoading = false {
        didSet {
            updateShowSkeleton()
        }
    }
    @Published var showSkeleton = false
    @Published var error: Error?
    @Published var showError = false

    var displayTitle: AttributedString {
        var title = AttributedString(item.displayTitle ?? "")
        if let movie = item as? MovieSchema, let year = movie.year {
            var yearString = AttributedString(" (\(year))")
            yearString.foregroundColor = .secondary
            title += yearString
        }
        return title
    }
    
    init(item: any ItemProtocol) {
        self.item = item
    }
    
    private func updateShowSkeleton() {
        showSkeleton = item.displayTitle == nil && isLoading
    }
    
    private func loadItemIfNeeded() {
        guard accountsManager != nil else { return }
        
        logger.debug("Checking if item needs loading: \(item.uuid)")
        // Only load if we don't have full details
        guard item.description == nil || item.rating == nil else { 
            logger.debug("Item already has full details")
            return 
        }
        
        loadItem(refresh: false)
    }
    
    func loadItem(refresh: Bool) {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        loadTask?.cancel()
        
        loadTask = Task {
            if !Task.isCancelled {
                isLoading = true
                logger.debug("Started loading item: \(item.uuid)")
            }
            
            // Try cache first if not refreshing
            if !refresh {
                logger.debug("Using cached item: \(item.uuid) with category: \(item.category)")
                if let cached = try? await cacheService.retrieveItem(id: item.uuid, category: item.category, instance: accountsManager.currentAccount.instance) {
                    if !Task.isCancelled {
                        logger.debug("Using cached item: \(item.uuid)")
                        item = cached
                        // Don't return here, continue with network request
                    }
                }
            }
            
            do {
                guard accountsManager.isAuthenticated else {
                    logger.error("Not authenticated")
                    throw NetworkError.unauthorized
                }
                
                // Fetch from network
                let endpoint = ItemEndpoint.make(id: item.uuid, category: item.category)
                let result = try await accountsManager.currentClient.fetch(endpoint, type: ItemSchema.make(category: item.category))
                
                if !Task.isCancelled {
                    logger.debug("Successfully loaded item: \(item.uuid)")
                    item = result
                    try? await cacheService.cacheItem(result, id: item.uuid, category: item.category, instance: accountsManager.currentAccount.instance)
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error("Failed to load item: \(error.localizedDescription)")
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 
