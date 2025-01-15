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
    private var loadTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                loadMarkIfNeeded()
            }
        }
    }
    
    @Published var mark: MarkSchema?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    private let itemId: String
    
    init(itemId: String) {
        self.itemId = itemId
    }
    
    // MARK: - Computed Properties
    
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
        guard mark == nil else { return }
        loadMark()
    }
    
    func loadMark() {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            if !Task.isCancelled {
                isLoading = true
            }
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                }
            }
            
            do {
                let endpoint = MarkEndpoint.get(itemId: itemId)
                let result = try await accountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
                
                if !Task.isCancelled {
                    mark = result
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error("Failed to load mark: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 