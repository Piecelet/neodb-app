//
//  MarkViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog
import SwiftUI

@MainActor
class MarkViewModel: ObservableObject {
    private let logger = Logger.views.mark.mark

    let item: (any ItemProtocol)
    let existingMark: MarkSchema?

    @Published var shelfType: ShelfType
    @Published var rating: Int?
    @Published var comment: String = ""
    @Published var visibility: MarkVisibility = .pub
    @AppStorage(\.mark.postToFediverse) public var postToFediverse: Bool = true
    @Published var createdTime: Date = Date()
    @Published var changeTime = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var isDismissed = false

    var accountsManager: AppAccountsManager?

    init(item: any ItemProtocol, mark: MarkSchema? = nil, shelfType: ShelfType? = nil) {
        self.item = item
        self.existingMark = mark
        self.shelfType = shelfType ?? .wishlist

        if let mark = mark {
            self.shelfType = mark.shelfType
            self.rating = mark.ratingGrade
            self.comment = mark.commentText ?? ""
            self.visibility = mark.visibility
            if let date = mark.createdTime?.asDate {
                self.createdTime = date
            }
        }
    }

    var title: String {
        item.displayTitle ?? item.title ?? (existingMark == nil ? 
            String(localized: "mark_title", table: "Item") : 
            String(localized: "mark_edit_title", table: "Item"))
    }

    func saveMark() async {
        guard let accountsManager = accountsManager else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let mark = MarkInSchema(
                shelfType: shelfType,
                visibility: visibility,
                commentText: comment.isEmpty ? nil : comment,
                ratingGrade: rating == 0 ? nil : rating,
                tags: [],
                createdTime: changeTime ? ServerDate.from(createdTime) : nil,
                postToFediverse: postToFediverse,
                postId: existingMark?.postId
            )

            let endpoint = MarkEndpoint.mark(itemId: item.uuid, mark: mark)
            _ = try await accountsManager.currentClient.fetch(
                endpoint, type: MessageSchema.self)

            isDismissed = true
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to save mark: \(error.localizedDescription)")
        }
    }

    func deleteMark() async {
        guard let accountsManager = accountsManager,
            existingMark != nil
        else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let endpoint = MarkEndpoint.delete(itemId: item.uuid)
            _ = try await accountsManager.currentClient.fetch(
                endpoint, type: MessageSchema.self)

            isDismissed = true
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to delete mark: \(error.localizedDescription)")
        }
    }
}
