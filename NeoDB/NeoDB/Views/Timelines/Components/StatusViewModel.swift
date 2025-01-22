//
//  StatusViewModel.swift
//  NeoDB
//
//  Created by citron on 2/10/25.
//

import Foundation
import OSLog
import UIKit

@MainActor
class StatusViewModel: ObservableObject {
    private let logger = Logger.views.status.status
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
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
    @Published var reblogsCount: Int
    @Published var favouritesCount: Int
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(status: MastodonStatus) {
        self.status = status
        self.isReblogged = status.reblogged ?? false
        self.isFavorited = status.favourited ?? false
        self.isBookmarked = status.bookmarked ?? false
        self.reblogsCount = status.reblogsCount
        self.favouritesCount = status.favouritesCount
    }
    
    private func updateInteractionStates() {
        isReblogged = status.reblogged ?? false
        isFavorited = status.favourited ?? false
        isBookmarked = status.bookmarked ?? false
        reblogsCount = status.reblogsCount
        favouritesCount = status.favouritesCount
    }
    
    func toggleReblog() {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        isLoading = true
        impactFeedback.impactOccurred()
        
        // Optimistically update UI
        isReblogged.toggle()
        reblogsCount += isReblogged ? 1 : -1
        
        Task {
            do {
                let endpoint = isReblogged ? 
                    StatusesEndpoints.reblog(id: status.id) :
                    StatusesEndpoints.unreblog(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                isReblogged = updatedStatus.reblogged ?? false
                reblogsCount = updatedStatus.reblogsCount
                
            } catch {
                // Revert optimistic updates on error
                isReblogged.toggle()
                reblogsCount += isReblogged ? 1 : -1
                
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
        impactFeedback.impactOccurred()
        
        // Optimistically update UI
        isFavorited.toggle()
        favouritesCount += isFavorited ? 1 : -1
        
        Task {
            do {
                let endpoint = isFavorited ? 
                    StatusesEndpoints.favorite(id: status.id) :
                    StatusesEndpoints.unfavorite(id: status.id)
                
                let updatedStatus = try await accountsManager.currentClient.fetch(endpoint, type: MastodonStatus.self)
                isFavorited = updatedStatus.favourited ?? false
                favouritesCount = updatedStatus.favouritesCount
                
            } catch {
                // Revert optimistic updates on error
                isFavorited.toggle()
                favouritesCount += isFavorited ? 1 : -1
                
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
        impactFeedback.impactOccurred()
        
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