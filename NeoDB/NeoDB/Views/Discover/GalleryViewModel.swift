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

    private var isLegacy = false
    
    init() {
        // Initialize states for all categories
        for category in ItemCategory.galleryCategory.availableCategories {
            galleryStates[category] = State(galleryCategory: category)
        }
    }
    
    // MARK: - Methods
    // func loadGallery(category: ItemCategory.galleryCategory, refresh: Bool = false) async {
    //     loadTasks[category]?.cancel()
        
    //     loadTasks[category] = Task {
    //         guard let accountsManager = accountsManager else {
    //             logger.debug("No accountsManager available")
    //             return
    //         }

    //         if isLegacy {
    //             Task {
    //                 await loadAllGalleries(refresh: refresh)
    //             }
    //             loadTasks[category]?.cancel()
    //         }
            
    //         updateLoadingState(for: category, refresh: refresh)
            
    //         defer {
    //             if !Task.isCancelled {
    //                 updateState(for: category) { state in
    //                     state.isLoading = false
    //                     state.isRefreshing = false
    //                 }
    //             }
    //         }
            
    //         // Load from cache first if not refreshing
    //         if !refresh {
    //             if let cached = try? await cacheService.retrieveGallery(
    //                 category: category,
    //                 instance: accountsManager.currentAccount.instance
    //             ) {
    //                 updateState(for: category) { state in
    //                     state.trendingGallery = cached
    //                     state.lastRefreshTime = Date()
    //                     state.isInited = true
    //                 }
    //             }
    //         }
            
    //         do {
    //             let endpoint = category.endpoint
    //             let result = try await accountsManager.currentClient.fetch(
    //                 endpoint, type: [ItemSchema].self)
                    
    //             updateState(for: category) { state in
    //                 state.trendingGallery = result
    //                 state.lastRefreshTime = Date()
    //                 state.error = nil
    //                 state.isInited = true
    //             }
                
    //             // Cache only if it's a refresh or first load
    //                 try? await cacheService.cacheGallery(
    //                     result,
    //                     category: category,
    //                     instance: accountsManager.currentAccount.instance
    //                 )
    //         } catch {
    //             if !Task.isCancelled {
    //                 updateState(for: category) { state in
    //                     state.error = error
    //                     if case .httpError(let code, _) = error as? NetworkError, code == 404 {
    //                         isLegacy = true
    //                     }
    //                     logger.error("Gallery load error: \(error.localizedDescription)")
    //                 }
    //             }
    //         }
    //     }
        
    //     await loadTasks[category]?.value
    // }
    
    private func updateState(for category: ItemCategory.galleryCategory, update: (inout State) -> Void) {
        var state = galleryStates[category] ?? State(galleryCategory: category)
        update(&state)
        galleryStates[category] = state
    }

    private func updateStateFromLegacy(galleryResults: [GalleryResult]) {
        for gallery in galleryResults {
            if let category = gallery.itemCategory {
                updateState(for: category) { state in
                    state.trendingGallery = gallery.items
                    state.lastRefreshTime = Date()
                    state.error = nil
                    state.isInited = true
                    self.isLegacy = true
                }
            }
        }
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
            
            // 检查是否所有分类都有数据
            let hasEmptyGalleries = ItemCategory.galleryCategory.availableCategories.contains { category in
                let state = galleryStates[category]
                return state?.trendingGallery.isEmpty ?? true
            }
            
            // 如果时间间隔太短且所有分类都有数据,则跳过请求
            if timeSinceLastRequest < minimumRefreshInterval && !hasEmptyGalleries {
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
                if isLegacy {
                    if let cached = try? await cacheService.retrieveGallery(
                        instance: accountsManager.currentAccount.instance
                    ) {
                        updateStateFromLegacy(galleryResults: cached)
                    }
                } else {
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
            }

            // Concurrent fetch for all categories
            if isLegacy {
                let result = try await accountsManager.currentClient.fetch(CatalogEndpoint.gallery, type: [GalleryResult].self)
                updateStateFromLegacy(galleryResults: result)
                
                // Cache results
                try? await cacheService.cacheGallery(
                    galleryResult: result,
                    instance: accountsManager.currentAccount.instance
                )
            } else {
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
