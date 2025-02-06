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
    private let markDataProvider = MarkDataControllerProvider.shared
    
    var markDataController: MarkDataController?

    let item: (any ItemProtocol)
    let existingMark: MarkSchema?

    @Published var shelfType: ShelfType {
        didSet {
            markDataController?.shelfType = shelfType
        }
    }
    @Published var rating: Int? {
        didSet {
            markDataController?.ratingGrade = rating
        }
    }
    @Published var comment: String = "" {
        didSet {
            markDataController?.commentText = comment
        }
    }
    @Published var visibility: MarkVisibility = .pub {
        didSet {
            markDataController?.visibility = visibility
        }
    }
    @AppStorage(\.mark.postToFediverse) public var postToFediverse: Bool = true
    @Published var createdTime: Date = Date()
    @Published var changeTime = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var isDismissed = false

    var accountsManager: AppAccountsManager? {
        didSet {
            if let accountsManager = accountsManager {
                if let mark = existingMark {
                    markDataController = markDataProvider.dataController(for: mark, appAccountsManager: accountsManager)
                } else {
                    markDataController = markDataProvider.dataController(for: item.uuid, appAccountsManager: accountsManager)
                }
                self.shelfType = markDataController?.shelfType ?? .wishlist
                self.rating = markDataController?.ratingGrade
                self.comment = markDataController?.commentText ?? ""
                self.visibility = markDataController?.visibility ?? .pub
                self.createdTime = markDataController?.createdTime?.asDate ?? Date()
            }
        }
    }

    init(item: any ItemProtocol, mark: MarkSchema? = nil, shelfType: ShelfType? = nil) {
        self.item = item
        self.existingMark = mark
        self.shelfType = shelfType ?? .wishlist

        // if let mark = mark {
        //     self.shelfType = mark.shelfType
        //     self.rating = mark.ratingGrade
        //     self.comment = mark.commentText ?? ""
        //     self.visibility = mark.visibility
        //     if let date = mark.createdTime?.asDate {
        //         self.createdTime = date
        //     }
        // }
    }

    var title: String {
        item.displayTitle ?? item.title ?? (markDataController?.mark == nil ? 
            String(localized: "mark_title", table: "Item") : 
            String(localized: "mark_edit_title", table: "Item"))
    }

    func saveMark() async {
        guard markDataController != nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // let mark = MarkInSchema(
            //     shelfType: markDataController?.shelfType,
            //     visibility: markDataController?.visibility,
            //     commentText: markDataController?.commentText.isEmpty ?? true ? nil : markDataController?.commentText,
            //     ratingGrade: markDataController?.rating == 0 ? nil : markDataController?.rating,
            //     tags: [],
            //     createdTime: changeTime ? ServerDate.from(createdTime) : nil,
            //     postToFediverse: postToFediverse,
            //     postId: markDataController?.mark?.postId
            // )

            await markDataController?.updateMark(changedTime: changeTime ? ServerDate.from(createdTime) : nil, postToFediverse: postToFediverse)
            isDismissed = true
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to save mark: \(error.localizedDescription)")
        }
    }

    func deleteMark() async {
        guard 
              markDataController != nil
        else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            await markDataController?.deleteMark(for: item.uuid)
            isDismissed = true
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to delete mark: \(error.localizedDescription)")
        }
    }
}
