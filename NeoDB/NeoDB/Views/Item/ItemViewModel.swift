//
//  ItemViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog
import SwiftUI

enum ItemState {
    case loading
    case loaded
    case error
}

@MainActor
final class ItemViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.views.item
    private let cacheService = CacheService()

    // MARK: - Task Management
    private var loadTask: Task<Void, Never>?
    private var markLoadTask: Task<Void, Never>?

    // MARK: - Published Properties
    @Published private(set) var item: (any ItemProtocol)?
    @Published private(set) var mark: MarkSchema?
    @Published private(set) var state: ItemState = .loading
    @Published var error: Error?
    @Published var showError = false
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isMarkLoading = false

    // MARK: - Private Properties
    private let initialItem: (any ItemProtocol)?

    // MARK: - Public Properties
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                if item == nil {
                    item = initialItem
                }
                loadMarkIfNeeded()
            }
        }
    }

    // MARK: - Computed Properties for UI
    var displayTitle: String { item?.displayTitle ?? "" }
    var coverImageURL: URL? { item?.coverImageUrl }
    var rating: String { item?.rating.map { String(format: "%.1f", $0) } ?? "" }
    var ratingCount: String { item?.ratingCount.map(String.init) ?? "0" }
    var description: String { item?.description ?? "" }
    var shelfType: ShelfType? { mark?.shelfType }

    var metadata: [String] {
        guard let item else { return [] }

        var metadata: [String] = []

        switch item {
        case let book as EditionSchema:
            metadata = book.keyMetadata
        case let movie as MovieSchema:
            metadata = movie.keyMetadata
        case let tv as TVShowSchema:
            metadata = tv.keyMetadata
        case let music as AlbumSchema:
            metadata = music.keyMetadata
        case let performance as PerformanceSchema:
            metadata = performance.keyMetadata
        case let podcast as PodcastSchema:
            metadata = podcast.keyMetadata
        case let game as GameSchema:
            metadata = game.keyMetadata
        default:
            break
        }

        return metadata
    }

    var shareURL: URL? {
        guard let item,
            let accountsManager
        else { return nil }

        return ItemURL.makeShareURL(
            for: item,
            instance: accountsManager.currentAccount.instance
        )
    }

    // MARK: - Initialization
    init(initialItem: (any ItemProtocol)? = nil) {
        self.initialItem = initialItem
        self.item = initialItem
    }

    // MARK: - Public Methods
    func loadItemDetail(
        id: String, category: ItemCategory, refresh: Bool = false
    ) async {
        loadTask?.cancel()

        loadTask = Task {
            guard let accountsManager else {
                logger.debug("No accountsManager available")
                return
            }

            await updateLoadingState(refresh: refresh)

            defer {
                if !Task.isCancelled {
                    isLoading = false
                    isRefreshing = false
                }
            }

            do {
                if !refresh,
                    let cached = try? await cacheService.retrieveItem(
                        id: id, category: category)
                {
                    await handleCachedItem(cached, id: id, category: category)
                    return
                }

                guard !Task.isCancelled else { return }

                let result = try await fetchItem(
                    id: id, category: category,
                    client: accountsManager.currentClient)
                await handleFetchedItem(result, id: id, category: category)

            } catch {
                await handleError(error)
            }
        }

        await loadTask?.value
    }

    func loadMarkIfNeeded() {
        guard mark == nil,
            let item
        else { return }
        loadMark(itemId: item.uuid, refresh: false)
    }

    func refresh() {
        guard let item else { return }
        loadMark(itemId: item.uuid, refresh: true)
    }

    func cleanup() {
        loadTask?.cancel()
        markLoadTask?.cancel()
        loadTask = nil
        markLoadTask = nil
    }

    // MARK: - Private Methods
    private func buildBookMetadata(_ book: EditionSchema) -> [String] {
        var metadata: [String] = []

        if !book.author.isEmpty {
            metadata.append(book.author.joined(separator: ", "))
        }
        if let pubHouse = book.pubHouse {
            metadata.append(pubHouse)
        }
        if let pubYear = book.pubYear {
            metadata.append(String(pubYear))
        }
        if let pages = book.pages {
            metadata.append("\(pages) pages")
        }

        return metadata
    }

    private func loadMark(itemId: String, refresh: Bool) {
        markLoadTask?.cancel()

        markLoadTask = Task {
            guard let accountsManager else {
                logger.debug("No accountsManager available")
                return
            }

            if !Task.isCancelled {
                if refresh {
                    isRefreshing = true
                } else {
                    isMarkLoading = true
                }
            }

            defer {
                if !Task.isCancelled {
                    isMarkLoading = false
                    isRefreshing = false
                }
            }

            do {
                if !refresh,
                    let cached = try? await getCachedMark(itemId: itemId)
                {
                    if !Task.isCancelled {
                        mark = cached
                    }
                }

                let endpoint = MarkEndpoint.get(itemId: itemId)
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: MarkSchema.self)

                if !Task.isCancelled {
                    mark = result
                    try? await cacheMark(result, itemId: itemId)
                }
            } catch {
                await handleMarkError(error, itemId: itemId)
            }
        }
    }

    private func updateLoadingState(refresh: Bool) {
        if !Task.isCancelled {
            if refresh {
                isRefreshing = true
            } else {
                isLoading = true
                state = .loading
            }
        }
    }

    private func handleCachedItem(
        _ cached: any ItemProtocol, id: String, category: ItemCategory
    ) async {
        if !Task.isCancelled {
            item = cached
            state = .loaded
            // Refresh in background
            Task {
                await refreshItemInBackground(id: id, category: category)
            }
        }
    }

    private func handleFetchedItem(
        _ result: any ItemProtocol, id: String, category: ItemCategory
    ) async {
        if !Task.isCancelled {
            item = result
            state = .loaded
            try? await cacheService.cacheItem(
                result, id: id, category: category)
        }
    }

    private func handleError(_ error: Error) async {
        if !Task.isCancelled {
            self.error = error
            self.showError = true
            state = .error
            logger.error("Failed to load item: \(error.localizedDescription)")
        }
    }

    private func handleMarkError(_ error: Error, itemId: String) async {
        if !Task.isCancelled {
            if let networkError = error as? NetworkError,
                case .httpError(let statusCode) = networkError,
                statusCode == 404
            {
                // 404 means no mark exists, which is a normal case
                mark = nil
                logger.debug("No mark found for item: \(itemId)")
            } else {
                // Only show error if we don't have cached data
                if mark == nil {
                    self.error = error
                    self.showError = true
                    logger.error(
                        "Failed to load mark: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchItem(
        id: String, category: ItemCategory, client: NetworkClient
    ) async throws -> any ItemProtocol {
        let endpoint = ItemEndpoint.make(id: id, category: category)
        return try await client.fetch(
            endpoint, type: ItemSchema.make(category: category))
    }

    private func getCachedMark(itemId: String) async throws -> MarkSchema? {
        let cacheKey = "mark_\(itemId)"
        return try await cacheService.retrieve(
            forKey: cacheKey, type: MarkSchema.self)
    }

    private func cacheMark(_ mark: MarkSchema, itemId: String) async throws {
        let cacheKey = "mark_\(itemId)"
        try await cacheService.cache(
            mark, forKey: cacheKey, type: MarkSchema.self)
    }

    private func refreshItemInBackground(id: String, category: ItemCategory)
        async
    {
        guard let accountsManager else { return }

        do {
            let result = try await fetchItem(
                id: id, category: category,
                client: accountsManager.currentClient)
            logger.debug("Cache \(id) \(category) item refreshed")
            try? await cacheService.cacheItem(
                result, id: id, category: category)

            if !Task.isCancelled {
                item = result
            }
        } catch {
            logger.error(
                "Background refresh failed: \(error.localizedDescription)")
        }
    }
}
