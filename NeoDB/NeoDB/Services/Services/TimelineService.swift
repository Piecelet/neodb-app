//
//  TimelineService.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Foundation
import OSLog

@MainActor
class TimelineService {
    private let accountsManager: AppAccountsManager
    private let logger = Logger.networkTimeline
    
    init(accountsManager: AppAccountsManager) {
        self.accountsManager = accountsManager
    }
    
    func getTimeline(maxId: String? = nil, sinceId: String? = nil, minId: String? = nil, limit: Int = 20, local: Bool = true) async throws -> [Status] {
        guard accountsManager.isAuthenticated else {
            logger.error("No access token available")
            throw NetworkError.unauthorized
        }
        
        logger.debug("Fetching timeline with params - maxId: \(maxId ?? "nil"), sinceId: \(sinceId ?? "nil"), minId: \(minId ?? "nil"), local: \(local)")
        
        let endpoint = TimelinesEndpoint.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: local)
        
        do {
            let statuses = try await accountsManager.currentClient.fetch(endpoint, type: [Status].self)
            logger.debug("Successfully fetched \(statuses.count) statuses")
            return statuses
        } catch {
            logger.error("Failed to fetch timeline: \(error.localizedDescription)")
            throw error
        }
    }
} 