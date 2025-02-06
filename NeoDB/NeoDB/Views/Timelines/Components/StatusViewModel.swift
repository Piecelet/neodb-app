//
//  StatusViewModel.swift
//  NeoDB
//
//  Created by citron on 2/10/25.
//

import Foundation
import OSLog

@MainActor
class StatusViewModel: ObservableObject {
    private let logger = Logger.views.status.status
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                objectWillChange.send()
            }
        }
    }
    
    @Published var status: MastodonStatus {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(status: MastodonStatus) {
        self.status = status
    }
    
    func toggleReblog() {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        isLoading = true
        HapticFeedback.impact(.medium)
        
        // Create new status with updated values
        let newReblogged = !(status.reblogged ?? false)
        status.reblogged = newReblogged
        status.reblogsCount += newReblogged ? 1 : -1
        
        Task {
            do {
                let endpoint = newReblogged ? 
                    StatusesEndpoint.reblog(id: status.id) :
                    StatusesEndpoint.unreblog(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                status = updatedStatus
                
            } catch {
                // Revert optimistic updates
                status.reblogged = !newReblogged
                status.reblogsCount += newReblogged ? -1 : 1
                
                self.error = error
                self.showError = true
                logger.error("Failed to toggle reblog: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    func toggleFavorite() {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        isLoading = true
        HapticFeedback.impact(.medium)
        
        // Create new status with updated values
        let newFavorited = !(status.favourited ?? false)
        status.favourited = newFavorited
        status.favouritesCount += newFavorited ? 1 : -1
        
        Task {
            do {
                let endpoint = newFavorited ? 
                    StatusesEndpoint.favorite(id: status.id) :
                    StatusesEndpoint.unfavorite(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                status = updatedStatus
                
            } catch {
                // Revert optimistic updates
                status.favourited = !newFavorited
                status.favouritesCount += newFavorited ? -1 : 1
                
                self.error = error
                self.showError = true
                logger.error("Failed to toggle favorite: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
    
    func toggleBookmark() {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        isLoading = true
        HapticFeedback.impact(.medium)
        
        // Create new status with updated values
        let newBookmarked = !(status.bookmarked ?? false)
        status.bookmarked = newBookmarked
        
        Task {
            do {
                let endpoint = newBookmarked ? 
                    StatusesEndpoint.bookmark(id: status.id) :
                    StatusesEndpoint.unbookmark(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                status = updatedStatus
                
            } catch {
                // Revert optimistic updates
                status.bookmarked = !newBookmarked
                
                self.error = error
                self.showError = true
                logger.error("Failed to toggle bookmark: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
} 
