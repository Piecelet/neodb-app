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
                updateInteractionStates()
            }
        }
    }
    
    let status: MastodonStatus
    
    @Published var isReblogged: Bool
    @Published var isFavorited: Bool
    @Published var isBookmarked: Bool
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(status: MastodonStatus) {
        self.status = status
        self.isReblogged = status.reblogged ?? false
        self.isFavorited = status.favourited ?? false
        self.isBookmarked = status.bookmarked ?? false
    }
    
    private func updateInteractionStates() {
        isReblogged = status.reblogged ?? false
        isFavorited = status.favourited ?? false
        isBookmarked = status.bookmarked ?? false
    }
    
    func toggleReblog() {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let endpoint = isReblogged ? 
                    StatusesEndpoints.unreblog(id: status.id) :
                    StatusesEndpoints.reblog(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                isReblogged = updatedStatus.reblogged ?? false
                
            } catch {
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
        
        Task {
            do {
                let endpoint = isFavorited ? 
                    StatusesEndpoints.unfavorite(id: status.id) :
                    StatusesEndpoints.favorite(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                isFavorited = updatedStatus.favourited ?? false
                
            } catch {
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
        
        Task {
            do {
                let endpoint = isBookmarked ? 
                    StatusesEndpoints.unbookmark(id: status.id) :
                    StatusesEndpoints.bookmark(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                isBookmarked = updatedStatus.bookmarked ?? false
                
            } catch {
                self.error = error
                self.showError = true
                logger.error("Failed to toggle bookmark: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
    }
} 