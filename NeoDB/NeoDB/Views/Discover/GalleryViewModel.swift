//
//  GalleryViewModel.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog

@MainActor
class GalleryViewModel: ObservableObject {
    private let logger = Logger.views.discover.gallery
    private let cacheService = CacheService.shared
    
    // MARK: - Dependencies
    var accountsManager: AppAccountsManager?
    
    // MARK: - Task Management
    private var loadTasks: [ItemCategory.galleryCategory: Task<Void, Never>] = [:]
    
    // MARK: - Published Properties
    @Published private(set) var galleryStates: [ItemCategory.galleryCategory: GalleryState] = [:]
    
    init() {
        // Initialize states for all categories
        for category in ItemCategory.galleryCategory.allCases {
            galleryStates[category] = GalleryState(galleryCategory: category)
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
    
    private func updateState(for category: ItemCategory.galleryCategory, update: (inout GalleryState) -> Void) {
        var state = galleryStates[category] ?? GalleryState(galleryCategory: category)
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
}

// MARK: - Gallery State
struct GalleryState {
    var galleryCategory: ItemCategory.galleryCategory
    var trendingGallery: TrendingItemResult? = nil
    var isLoading = false
    var isRefreshing = false
    var error: Error?
    var lastRefreshTime: Date?
}
