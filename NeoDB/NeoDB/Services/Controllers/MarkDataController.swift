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
    func updateMark(for mark: MarkInSchema) async throws
    func deleteMark(for UUID: String) async throws
}

@MainActor
final class MarkDataControllerProvider {
    static let shared = MarkDataControllerProvider()

    private var dictionary: NSMutableDictionary = [:]

    private struct DictionaryKey: Hashable {
        let itemUUID: String
        let accountID: String
    }

    func dataController(for uuid: String, appAccountsManager: AppAccountsManager) -> MarkDataController {
        let key = DictionaryKey(itemUUID: uuid, accountID: appAccountsManager.currentAccount.id)
        if let controller = dictionary[key] as? MarkDataController {
            return controller
        }
        let controller = MarkDataController(uuid: uuid, appAccountsManager: appAccountsManager)
        dictionary[key] = controller
        return controller
    }

    func dataController(for mark: MarkSchema, appAccountsManager: AppAccountsManager) -> MarkDataController {
        let key = DictionaryKey(itemUUID: mark.item.uuid, accountID: appAccountsManager.currentAccount.id)
        if let controller = dictionary[key] as? MarkDataController {
            return controller
        }
        let controller = MarkDataController(uuid: mark.item.uuid, appAccountsManager: appAccountsManager, mark: mark)
        dictionary[key] = controller
        return controller
    }

    func updateDataControllers(for UUIDs: [String], appAccountsManager: AppAccountsManager) {
        for uuid in UUIDs {
            let controller = dataController(for: uuid, appAccountsManager: appAccountsManager)
            controller.updateForm(for: uuid)
        }
    }

    func updateDataControllers(for marks: [MarkSchema], appAccountsManager: AppAccountsManager) {
        for mark in marks {
            let controller = dataController(for: mark, appAccountsManager: appAccountsManager)
            controller.updateForm(for: mark)
        }
    }
}

@MainActor
final class MarkDataController: MarkDataControlling {
    private let uuid: String
    private let appAccountsManager: AppAccountsManager
    private let logger = Logger.dataControllers.markDataController

    @Published var mark: MarkSchema?
    @Published var shelfType: ShelfType = .wishlist
    @Published var commentText: String = ""
    @Published var ratingGrade: Int?
    @Published var visibility: MarkVisibility = .pub
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

    func updateForm(for mark: MarkSchema) {
        self.mark = mark
        self.shelfType = mark.shelfType
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.visibility = mark.visibility
        self.createdTime = mark.createdTime
        self.tags = mark.tags
    }

    func updateForm(for UUID: String) {
        self.mark = nil
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
            let fetchedMark = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
            updateForm(for: fetchedMark)
        } catch {
            logger.error("Failed to get mark: \(error.localizedDescription)")
        }
    }

    func updateMark(for mark: MarkInSchema) async throws {
        let previousMark = self.mark

        self.shelfType = mark.shelfType
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.visibility = mark.visibility
        self.createdTime = mark.createdTime ?? previousMark?.createdTime
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
                    createdTime: mark.createdTime ?? previousMark.createdTime,
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
                self.commentText = ""
                self.ratingGrade = nil
                self.visibility = .pub
                self.createdTime = nil
            }
            throw error
        }
    }

    func updateMark(changedTime: ServerDate? = nil, postToFediverse: Bool? = nil) async throws {

        do {
            if let ratingGrade = self.ratingGrade {
                let markIn = MarkInSchema(
                    shelfType: self.shelfType,
                    visibility: self.visibility,
                    commentText: self.commentText,
                    ratingGrade: ratingGrade == 0 ? nil : ratingGrade,
                    tags: tags,
                    createdTime: changedTime,
                    postToFediverse: postToFediverse,
                    postId: nil
                )
                let markEndpoint = MarkEndpoint.mark(itemUUID: uuid, mark: markIn)
                _ = try await appAccountsManager.currentClient.fetch(markEndpoint, type: MessageSchema.self)

                if let previousMark = self.mark {
                    let newMark = MarkSchema(
                        shelfType: shelfType,
                        visibility: visibility,
                        postId: previousMark.postId,
                        item: previousMark.item,
                        createdTime: changedTime,
                        commentText: commentText,
                        ratingGrade: ratingGrade == 0 ? nil : ratingGrade,
                        tags: tags
                    )
                    self.mark = newMark
                } else {
                    self.mark = markIn.toMarkSchema(item: ItemSchema.makeTemporaryItemSchema(uuid: uuid))
                }
            } else {
                throw NetworkError.invalidURL
            }
        } catch {
            logger.error("Failed to update mark: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteMark(for UUID: String) async throws {
        do {
            let endpoint = MarkEndpoint.delete(itemUUID: UUID)
            _ = try await appAccountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
        } catch {
            logger.error("Failed to delete mark: \(error.localizedDescription)")
            throw error
        }
    }
}
