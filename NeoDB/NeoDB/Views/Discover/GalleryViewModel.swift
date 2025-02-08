//
//  GalleryViewModel.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog

// MARK: - Gallery State

@MainActor
class GalleryViewModel: ObservableObject {

    struct State {
        var galleryCategory: ItemCategory.galleryCategory
        var trendingGallery: TrendingItemResult = []
        var isLoading = false
        var isRefreshing = false
        var error: Error?
        var lastRefreshTime: Date?
        var isInited = false
    }

    private let logger = Logger.views.discover.gallery
    private let cacheService = CacheService.shared
    
    // MARK: - Dependencies
    var accountsManager: AppAccountsManager?
    
    // MARK: - Task Management
    private var loadTasks: [ItemCategory.galleryCategory: Task<Void, Never>] = [:]
    
    // MARK: - Published Properties
    @Published private(set) var galleryStates: [ItemCategory.galleryCategory: State] = [:]
    
    // MARK: - Constants
    private let minimumRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    
    // MARK: - Properties
    private var lastRequestTime: Date?
    
    init() {
        // Initialize states for all categories
        for category in ItemCategory.galleryCategory.availableCategories {
            galleryStates[category] = State(galleryCategory: category)
        }
    }
    
    // MARK: - Methods
    func loadGallery(category: ItemCategory.galleryCategory, refresh: Bool = false) async {
        loadTasks[category]?.cancel()
        
        loadTasks[category] = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            updateLoadingState(for: category, refresh: refresh)
            
            defer {
                if !Task.isCancelled {
                    updateState(for: category) { state in
                        state.isLoading = false
                        state.isRefreshing = false
                    }
                }
            }
            
            // Load from cache first if not refreshing
            if !refresh {
                if let cached = try? await cacheService.retrieveGallery(
                    category: category,
                    instance: accountsManager.currentAccount.instance
                ) {
                    updateState(for: category) { state in
                        state.trendingGallery = cached
                        state.lastRefreshTime = Date()
                        state.isInited = true
                    }
                }
            }
            
            do {
                let endpoint = category.endpoint
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: [ItemSchema].self)
                    
                updateState(for: category) { state in
                    state.trendingGallery = result
                    state.lastRefreshTime = Date()
                    state.error = nil
                    state.isInited = true
                }
                
                // Cache only if it's a refresh or first load
                if refresh || galleryStates[category]?.trendingGallery == nil {
                    try? await cacheService.cacheGallery(
                        result,
                        category: category,
                        instance: accountsManager.currentAccount.instance
                    )
                }
            } catch {
                if !Task.isCancelled {
                    updateState(for: category) { state in
                        state.error = error
                        logger.error("Gallery load error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        await loadTasks[category]?.value
    }
    
    private func updateState(for category: ItemCategory.galleryCategory, update: (inout State) -> Void) {
        var state = galleryStates[category] ?? State(galleryCategory: category)
        update(&state)
        galleryStates[category] = state
    }
    
    private func updateLoadingState(for category: ItemCategory.galleryCategory, refresh: Bool) {
        updateState(for: category) { state in
            state.isLoading = true
            if refresh {
                state.isRefreshing = true
                state.error = nil
            }
        }
    }
    
    func cleanup() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
    }
    
    func loadAllGalleries(refresh: Bool = false) async {
        guard let accountsManager = accountsManager else {
            logger.debug("No accountsManager available")
            return
        }
        
        // Check if enough time has passed since last request
        if !refresh, let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minimumRefreshInterval {
                logger.debug("Skipping request - too soon since last request (\(Int(timeSinceLastRequest))s < \(Int(minimumRefreshInterval))s)")
                return
            }
        }
        
        lastRequestTime = Date()
        
        // Update loading states
        for category in ItemCategory.galleryCategory.availableCategories {
            updateLoadingState(for: category, refresh: refresh)
        }

        do {
            // Load from cache first if not refreshing
            if !refresh {
                for category in ItemCategory.galleryCategory.availableCategories {
                    if let cached = try? await cacheService.retrieveGallery(
                        category: category,
                        instance: accountsManager.currentAccount.instance
                    ) {
                        updateState(for: category) { state in
                            state.trendingGallery = cached
                            state.lastRefreshTime = Date()
                            state.isInited = true
                        }
                    }
                }
            }

            // Concurrent fetch for all categories
            try await withThrowingTaskGroup(of: (ItemCategory.galleryCategory, [ItemSchema]).self) { group in
                for category in ItemCategory.galleryCategory.availableCategories {
                    group.addTask {
                        let result = try await accountsManager.currentClient.fetch(
                            category.endpoint, type: [ItemSchema].self)
                        return (category, result)
                    }
                }

                // Process results as they complete
                for try await (category, result) in group {
                    updateState(for: category) { state in
                        state.trendingGallery = result
                        state.lastRefreshTime = Date()
                        state.error = nil
                        state.isInited = true
                    }

                    // Cache results
                    if refresh || galleryStates[category]?.trendingGallery == nil {
                        try? await cacheService.cacheGallery(
                            result,
                            category: category,
                            instance: accountsManager.currentAccount.instance
                        )
                    }
                }
            }
        } catch {
            logger.error("Failed to load galleries: \(error.localizedDescription)")
            // Update error state for all categories
            for category in ItemCategory.galleryCategory.availableCategories {
                updateState(for: category) { state in
                    state.error = error
                }
            }
        }

        // Reset loading states
        for category in ItemCategory.galleryCategory.availableCategories {
            updateState(for: category) { state in
                state.isLoading = false
                state.isRefreshing = false
            }
        }
    }
}
