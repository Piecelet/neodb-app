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
    let item: (any ItemProtocol)?
    private var loadTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                loadMarkIfNeeded()
            }
        }
    }
    
    var onAddToShelf: () -> Void = {}
    
    @Published var mark: MarkSchema?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(item: (any ItemProtocol)?) {
        self.item = item
    }
    
    // MARK: - Computed Properties
    
    var shareURL: URL? {
        guard let item = item,
              let accountsManager = accountsManager else { return nil }
        return ItemURL.makeShareURL(for: item, instance: accountsManager.currentAccount.instance)
    }
    
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
        guard mark == nil, let item = item else { return }
        loadMark(itemId: item.uuid)
    }
    
    private func loadMark(itemId: String) {
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