//
//  MastodonTimelinesViewModel.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog
import SwiftUI

@MainActor
final class MastodonTimelinesViewModel: ObservableObject {
    // MARK: - Properties
    private let logger = Logger.views.timelines
    private let cacheService = CacheService.shared
    private var loadTasks: [MastodonTimelinesFilter: Task<Void, Never>] = [:]
    
    @Published private(set) var timelineStates: [MastodonTimelinesFilter: MastodonTimelinesState] = [
        .following: MastodonTimelinesState(),
        .local: MastodonTimelinesState(),
        .trending: MastodonTimelinesState(),
        .federated: MastodonTimelinesState()
    ]
    
    var accountsManager: AppAccountsManager?
    
    private let minimumRefreshInterval: TimeInterval = 60 // 1 minute
    
    // MARK: - Methods
    func loadTimeline(type: MastodonTimelinesFilter, refresh: Bool = false) async {
        loadTasks[type]?.cancel()
        
        loadTasks[type] = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            // Check refresh time if not a forced refresh
            if !refresh,
               let state = timelineStates[type],
               let lastRefresh = state.lastRefreshTime,
               !state.statuses.isEmpty,
               Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
                return
            }
            
            updateLoadingState(type: type, refresh: refresh)
            
            defer {
                if !Task.isCancelled {
                    updateState(for: type) { state in
                        state.isLoading = false
                        state.isRefreshing = false
                    }
                }
            }
            
            // Load from cache first if not refreshing
            if !refresh {
                if let cached = try? await cacheService.retrieveTimelines(
                    key: "\(accountsManager.currentAccount.id)_\(type.rawValue)")
                {
                    updateState(for: type) { state in
                        if state.statuses.isEmpty {
                            state.statuses = cached
                            state.lastRefreshTime = Date()
                        }
                    }
                }
            }
            
            do {
                let state = timelineStates[type] ?? MastodonTimelinesState()
                let endpoint = type.endpoint(maxId: state.maxId)
                
                let newStatuses = try await accountsManager.currentClient.fetch(
                    endpoint, type: [MastodonStatus].self)
                
                updateState(for: type) { state in
                    if refresh {
                        state.statuses = newStatuses
                    } else {
                        let existingIds = Set(state.statuses.map(\.id))
                        let uniqueNewStatuses = newStatuses.filter { !existingIds.contains($0.id) }
                        state.statuses.append(contentsOf: uniqueNewStatuses)
                    }
                    state.maxId = newStatuses.last?.id
                    state.hasMore = !newStatuses.isEmpty
                    state.lastRefreshTime = Date()
                    state.error = nil
                    state.isInited = true
                }
                
                // Cache only if it's a refresh or first load
                if refresh || state.statuses.isEmpty {
                    try? await cacheService.cacheTimelines(
                        timelineStates[type]?.statuses ?? [],
                        key: "\(accountsManager.currentAccount.id)_\(type.rawValue)")
                }
            } catch {
                if !Task.isCancelled {
                    updateState(for: type) { state in
                        state.error = error
                        logger.error("Timeline load error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        await loadTasks[type]?.value
    }
    
    private func updateState(for type: MastodonTimelinesFilter, update: (inout MastodonTimelinesState) -> Void) {
        var state = timelineStates[type] ?? MastodonTimelinesState()
        update(&state)
        timelineStates[type] = state
    }
    
    private func updateLoadingState(type: MastodonTimelinesFilter, refresh: Bool) {
        updateState(for: type) { state in
            state.isLoading = true
            if refresh {
                state.maxId = nil
                state.isRefreshing = true
                state.error = nil
            }
        }
    }
    
    func cleanup() {
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
        
        // Mark all timelines as inactive
        for type in MastodonTimelinesFilter.allCases {
            updateState(for: type) { state in
                state.isActive = false
            }
        }
    }
}

