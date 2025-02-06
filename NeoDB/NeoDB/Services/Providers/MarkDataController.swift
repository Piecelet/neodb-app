//
//  MarkDataController.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog

@MainActor
protocol MarkDataControlling {
    func updateMark(for mark: MarkInSchema) async
    func deleteMark(for UUID: String) async
}

@MainActor
final class MarkDataControllerProvider {
    static let shared = MarkDataControllerProvider()

    private var dictionary: NSMutableDictionary = [:]

    private struct DictionaryKey: Hashable {
        let uuid: String
        let accountID: String
    }

    func dataController(for uuid: String, appAccountsManager: AppAccountsManager) -> MarkDataController {
        let key = DictionaryKey(uuid: uuid, accountID: appAccountsManager.currentAccount.id)
        if let controller = dictionary[key] as? MarkDataController {
            return controller
        }
        let controller = MarkDataController(uuid: uuid, appAccountsManager: appAccountsManager)
        dictionary[key] = controller
        return controller
    }

    func dataController(for mark: MarkSchema, appAccountsManager: AppAccountsManager) -> MarkDataController {
        let key = DictionaryKey(uuid: mark.item.uuid, accountID: appAccountsManager.currentAccount.id)
        if let controller = dictionary[key] as? MarkDataController {
            return controller
        }
        let controller = MarkDataController(uuid: mark.item.uuid, appAccountsManager: appAccountsManager, mark: mark)
        dictionary[key] = controller
        return controller
    }

    func updateDataControllers(for UUIDs: [String], appAccountsManager: AppAccountsManager) {
        for uuid in UUIDs {
            _ = dataController(for: uuid, appAccountsManager: appAccountsManager)
        }
    }

    func updateDataController(for marks: [MarkSchema], appAccountsManager: AppAccountsManager) {
        for mark in marks {
            _ = dataController(for: mark, appAccountsManager: appAccountsManager)
        }
    }
}

@MainActor
final class MarkDataController: MarkDataControlling {
    private let uuid: String
    private let appAccountsManager: AppAccountsManager
    private let logger = Logger.views.mark.mark

    @Published var mark: MarkSchema?
    @Published var shelfType: ShelfType?
    @Published var commentText: String?
    @Published var ratingGrade: Int?
    @Published var visibility: MarkVisibility?
    @Published var createdTime: ServerDate?
    @Published var tags: [String] = []

    init(uuid: String, appAccountsManager: AppAccountsManager, mark: MarkSchema? = nil) {
        self.uuid = uuid
        self.appAccountsManager = appAccountsManager
        self.mark = mark

        Task {
            await getMark()
        }
    }

    func getMark() async {
        if let mark = mark {
            self.shelfType = mark.shelfType
            self.commentText = mark.commentText
            self.ratingGrade = mark.ratingGrade
            self.visibility = mark.visibility
            self.createdTime = mark.createdTime
            self.tags = mark.tags
            return
        }

        do {
            let endpoint = MarkEndpoint.get(itemUUID: uuid)
            mark = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
        } catch {
            logger.error("Failed to get mark: \(error.localizedDescription)")
        }
    }

    func updateMark(for mark: MarkInSchema) async {
        let previousMark = self.mark

        self.shelfType = mark.shelfType
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.visibility = mark.visibility
        self.createdTime = mark.createdTime
        self.tags = mark.tags
        do {
            let markEndpoint = MarkEndpoint.mark(itemUUID: uuid, mark: mark)
            _ = try await appAccountsManager.currentClient.fetch(markEndpoint, type: MessageSchema.self)
            if let previousMark = previousMark {
                let newMark = MarkSchema(
                    shelfType: mark.shelfType,
                    visibility: mark.visibility,
                    postId: previousMark.postId,
                    item: previousMark.item,
                    createdTime: mark.createdTime,
                    commentText: mark.commentText,
                    ratingGrade: mark.ratingGrade,
                    tags: mark.tags
                )
                self.mark = newMark
            } else {
                self.mark = mark.toMarkSchema(item: ItemSchema.makeTemporaryItemSchema(uuid: uuid))
            }
        } catch {
            logger.error("Failed to update mark: \(error.localizedDescription)")
            if let previousMark = previousMark {
                self.mark = previousMark
                self.shelfType = previousMark.shelfType
                self.commentText = previousMark.commentText
                self.ratingGrade = previousMark.ratingGrade
                self.visibility = previousMark.visibility
                self.createdTime = previousMark.createdTime
                self.tags = previousMark.tags
            } else {
                self.mark = nil
                self.shelfType = nil
                self.commentText = nil
                self.ratingGrade = nil
                self.visibility = nil
                self.createdTime = nil
                self.tags = []
            }
        }
    }

    func deleteMark(for UUID: String) async {
        do {
            let endpoint = MarkEndpoint.delete(itemUUID: UUID)
            _ = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
        } catch {
            logger.error("Failed to delete mark: \(error.localizedDescription)")
        }
    }
}
