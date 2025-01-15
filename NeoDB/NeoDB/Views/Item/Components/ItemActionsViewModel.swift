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
    private let logger = Logger.views.item
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
        // Extract UUID from URL if needed
        if let url = URL(string: itemId), url.pathComponents.count >= 2 {
            self.itemId = url.lastPathComponent
        } else {
            self.itemId = itemId
        }
        logger.debug("Initialized ItemActionsViewModel with itemId: \(self.itemId)")
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
        guard mark == nil else {
            logger.debug("Mark already loaded, skipping loadMark")
            return
        }
        loadMark()
    }
    
    func loadMark() {
        loadTask?.cancel()
        
        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }
            
            guard !itemId.isEmpty else {
                logger.error("Invalid itemId: empty string")
                return
            }
            
            logger.debug("Loading mark for itemId: \(itemId)")
            
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
                logger.debug("Fetching mark with endpoint: \(String(describing: endpoint))")
                
                let result = try await accountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
                logger.debug("Successfully loaded mark: \(String(describing: result))")
                
                if !Task.isCancelled {
                    mark = result
                }
            } catch let error as NetworkError {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error("Network error loading mark: \(error.localizedDescription), status: \(String(describing: error))")
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
        logger.debug("Cleaning up ItemActionsViewModel")
        loadTask?.cancel()
        loadTask = nil
    }
} 
