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

    private let statusDataControllerProvider = StatusDataControllerProvider.shared
    var statusDataController: StatusDataController?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if let accountsManager = accountsManager {
                statusDataController = statusDataControllerProvider.dataController(
                    for: status,
                    appAccountsManager: accountsManager
                )
            }
        }
    }
    
    @Published var status: MastodonStatus
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(status: MastodonStatus) {
        self.status = status
    }
    
    func toggleReblog() {
        guard let statusDataController = statusDataController else {
            logger.error("No statusDataController available")
            return
        }
        
        HapticFeedback.impact(.medium)

        Task {
            await statusDataController.toggleReblog(remoteStatus: status.id)
        }
    }
    
    func toggleFavorite() {
        guard let statusDataController = statusDataController else {
            logger.error("No statusDataController available")
            return
        }
        
        HapticFeedback.impact(.medium)
        
        Task {
            await statusDataController.toggleFavorite(remoteStatus: status.id)
        }
    }

    func toggleBookmark() {
        guard let statusDataController = statusDataController else {
            logger.error("No statusDataController available")
            return
        }
        
        HapticFeedback.impact(.medium)
        
        Task {
            await statusDataController.toggleBookmark(remoteStatus: status.id)
        }
    }
}
