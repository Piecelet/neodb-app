//
//  StatusDataController.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog
import SwiftUI

@MainActor
protocol StatusDataControlling: ObservableObject {
    var isReblogged: Bool { get set }
    var isBookmarked: Bool { get set }
    var isFavorited: Bool { get set }

    var favoritesCount: Int { get set }
    var reblogsCount: Int { get set }
    var repliesCount: Int { get set }

    func toggleBookmark(remoteStatus: String?) async
    func toggleReblog(remoteStatus: String?) async
    func toggleFavorite(remoteStatus: String?) async
}

@MainActor
final class StatusDataControllerProvider {
    static let shared = StatusDataControllerProvider()

    private var dictionary: NSMutableDictionary = [:]

    private struct DictionaryKey: Hashable {
        let statusId: String
        let accountID: String
    }

    func dataController(
        for status: any AnyMastodonStatus, accountsManager: AppAccountsManager
    ) -> StatusDataController {
        let key = DictionaryKey(
            statusId: status.id, accountID: accountsManager.currentAccount.id)
        if let controller = dictionary[key] as? StatusDataController {
            return controller
        }
        let controller = StatusDataController(
            status: status, accountsManager: accountsManager)
        dictionary[key] = controller
        return controller
    }

    func updateDataControllers(
        for statuses: [MastodonStatus], accountsManager: AppAccountsManager
    ) {
        for status in statuses {
            let realStatus: AnyMastodonStatus = status.reblog ?? status
            let controller = dataController(
                for: realStatus, accountsManager: accountsManager)
            controller.updateFrom(status: realStatus)
        }
    }
}

@MainActor
final class StatusDataController: StatusDataControlling {
    // MARK: - Properties
    nonisolated let status: AnyMastodonStatus
    private let accountsManager: AppAccountsManager
    private let logger = Logger.dataControllers.statusDataController
    // private var unfetchedItem: (any ItemProtocol)? = nil

    @Published var isReblogged: Bool
    @Published var isBookmarked: Bool
    @Published var isFavorited: Bool
    @Published var content: HTMLString

    @Published var favoritesCount: Int
    @Published var reblogsCount: Int
    @Published var repliesCount: Int

    @Published var item: (any ItemProtocol)? = nil

    init(status: AnyMastodonStatus, accountsManager: AppAccountsManager) {
        self.status = status
        self.accountsManager = accountsManager
        // self.unfetchedItem = status.content.links.compactMap(\.neodbItem).first

        isReblogged = status.reblogged == true
        isBookmarked = status.bookmarked == true
        isFavorited = status.favourited == true

        reblogsCount = status.reblogsCount
        repliesCount = status.repliesCount
        favoritesCount = status.favouritesCount
        content = status.content

        // Task {
        //     await getItem()
        // }

        self.item = status.content.links.compactMap(\.neodbItem).first
    }

    func updateFrom(status: AnyMastodonStatus) {
        Task {
            let endpoint = StatusesEndpoint.status(id: status.id)
            do {
                let status = try await accountsManager.currentClient.fetch(
                    endpoint, type: MastodonStatus.self)
                isReblogged = status.reblogged == true
                isBookmarked = status.bookmarked == true
                isFavorited = status.favourited == true

                reblogsCount = status.reblogsCount
                repliesCount = status.repliesCount
                favoritesCount = status.favouritesCount
                content = status.content
            } catch {
                logger.error(
                    "Failed to update from status: \(error.localizedDescription)"
                )
            }
        }
    }

    // private func getItem() async {
    //     guard let item = unfetchedItem else { return }
    //     do {
    //         let endpoint = ItemEndpoint.make(
    //             id: item.id, category: item.category)
    //         let fetchedItem = try await accountsManager.currentClient.fetch(
    //             endpoint, type: ItemSchema.self)
    //         self.item = fetchedItem
    //     } catch {
    //         logger.error("Failed to get item: \(error.localizedDescription)")
    //     }
    // }

    func toggleFavorite(remoteStatus: String? = nil) async {
        guard accountsManager.isAuthenticated else { return }
        isFavorited.toggle()
        let id = remoteStatus ?? status.id
        let endpoint =
            isFavorited
            ? StatusesEndpoint.favorite(id: id)
            : StatusesEndpoint.unfavorite(id: id)
        withAnimation(.default) {
            favoritesCount += isFavorited ? 1 : -1
        }
        do {
            let status = try await accountsManager.currentClient.fetch(
                endpoint, type: MastodonStatus.self)
            updateFrom(status: status.reblog ?? status)
        } catch {
            isFavorited.toggle()
            favoritesCount += isFavorited ? -1 : 1
        }
    }

    func toggleReblog(remoteStatus: String? = nil) async {
        guard accountsManager.isAuthenticated else { return }
        isReblogged.toggle()
        let id = remoteStatus ?? status.id
        let endpoint =
            isReblogged
            ? StatusesEndpoint.reblog(id: id)
            : StatusesEndpoint.unreblog(id: id)
        withAnimation(.default) {
            reblogsCount += isReblogged ? 1 : -1
        }
        do {
            let status = try await accountsManager.currentClient.fetch(
                endpoint, type: MastodonStatus.self)
            updateFrom(status: status.reblog ?? status)
        } catch {
            isReblogged.toggle()
            reblogsCount += isReblogged ? -1 : 1
        }
    }

    func toggleBookmark(remoteStatus: String? = nil) async {
        guard accountsManager.isAuthenticated else { return }
        isBookmarked.toggle()
        let id = remoteStatus ?? status.id
        let endpoint =
            isBookmarked
            ? StatusesEndpoint.bookmark(id: id)
            : StatusesEndpoint.unbookmark(id: id)
        do {
            let status = try await accountsManager.currentClient.fetch(
                endpoint, type: MastodonStatus.self)
            updateFrom(status: status.reblog ?? status)
        } catch {
            isBookmarked.toggle()
        }
    }
}
