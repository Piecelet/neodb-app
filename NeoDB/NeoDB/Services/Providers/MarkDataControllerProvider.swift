//
//  MarkDataControllerProvider.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog

@MainActor
protocol MarkDataControlling {
    func updateMark(for mark: MarkSchema) async throws
    func deleteMark(for mark: MarkSchema) async throws
}

@MainActor
final class MarkDataControllerProvider: MarkDataControlling {
    static let shared = MarkDataControllerProvider()

    private let cacheService: CacheService

    init() {
        self.cacheService = CacheService.shared
    }

    func dataController(for mark: MarkSchema, accountID: String) -> MarkDataController {
        let key = CacheKey(uuid: uuid)
        if let controller = cache[key] as? MarkDataController {
            return controller
        }
        let controller = MarkDataController(uuid: uuid)
        cache[key] = controller
    }
    
    func updateMark(uuid: String, mark: MarkInSchema) async throws {
        let endpoint = MarkEndpoint.mark(itemId: uuid, mark: mark)
        let mark = try await accountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
    }
}

@MainActor
final class MarkDataController: MarkDataControlling {
    private let uuid: String
    private var mark: MarkSchema?
    private let appAccountsManager: AppAccountsManager
    private let logger = Logger.views.mark.mark

    @Published var shelfType: ShelfType
    @Published var commentText: String?
    @Published var ratingGrade: Int?
    @Published var visibility: MarkVisibility = .pub
    @Published var createdTime: Date = Date()

    init(uuid: String, appAccountsManager: AppAccountsManager) {
        self.uuid = uuid
        self.appAccountsManager = appAccountsManager

        Task {
            await getMark()
        }
    }

    func getMark() async {
        do {
            let endpoint = MarkEndpoint.get(itemUUID: uuid)
            mark = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
        } catch {
            logger.error("Failed to get mark: \(error.localizedDescription)")
        }
    }

    func updateMark(for mark: MarkSchema) async {
        let markIn = MarkInSchema(
            shelfType: shelfType,
            visibility: visibility,
            commentText: commentText,
            ratingGrade: ratingGrade,
            tags: mark.tags,
            createdTime: mark.createdTime,
            postToFediverse: false,
            postId: mark.postId
        )
        
        let endpoint = MarkEndpoint.mark(itemUUID: mark.item.uuid, mark: markIn)
        _ = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
    }

    func deleteMark(for mark: MarkSchema) async throws {
        let endpoint = MarkEndpoint.deleteMark(itemUUID: mark.item.uuid)
        _ = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
    }
}
