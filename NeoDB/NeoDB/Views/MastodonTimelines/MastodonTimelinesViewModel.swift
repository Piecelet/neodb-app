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
    
    @Published private(set) var statuses: [MastodonStatus] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    var accountsManager: AppAccountsManager?
    
    // MARK: - Methods
    func loadTimeline(type: MastodonTimelinesFilter, refresh: Bool = false) async {
        guard let accountsManager = accountsManager else {
            logger.debug("No accountsManager available")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let endpoint = type.endpoint()
            let newStatuses = try await accountsManager.currentClient.fetch(endpoint, type: [MastodonStatus].self)
            
            if refresh {
                statuses = newStatuses
            } else {
                let existingIds = Set(statuses.map(\.id))
                let uniqueNewStatuses = newStatuses.filter { !existingIds.contains($0.id) }
                statuses.append(contentsOf: uniqueNewStatuses)
            }
            error = nil
        } catch {
            self.error = error
            logger.error("Timeline load error: \(error.localizedDescription)")
        }
    }
    
    func cleanup() {
        statuses.removeAll()
        error = nil
    }
}

