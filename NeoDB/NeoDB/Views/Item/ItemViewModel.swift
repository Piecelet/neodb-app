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
class ItemViewModel: ObservableObject {
    private let logger = Logger.views.item
    private let cacheService = CacheService()
    private var loadTask: Task<Void, Never>?

    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                if item == nil {
                    item = initialItem
                }
            }
        }
    }

    @Published var item: (any ItemProtocol)?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showError = false

    private let initialItem: (any ItemProtocol)?

    init(initialItem: (any ItemProtocol)? = nil) {
        self.initialItem = initialItem
        self.item = initialItem
    }

    var state: ItemState {
        if isLoading {
            return .loading
        }
        if error != nil {
            return .error
        }
        return .loaded
    }

    // Computed properties for UI
    var displayTitle: String { item?.displayTitle ?? "" }
    var coverImageURL: URL? { item?.coverImageUrl }
    var rating: String {
        if let rating = item?.rating {
            return String(format: "%.1f", rating)
        }
        return "N/A"
    }
    var ratingCount: String { item?.ratingCount.map(String.init) ?? "0" }
    var description: String { item?.description ?? "" }

    var shareURL: URL? {
        guard let item = item,
            let accountsManager = accountsManager
        else { return nil }
        return ItemURL.makeShareURL(
            for: item, instance: accountsManager.currentAccount.instance)
    }

    func loadItemDetail(
        id: String, category: ItemCategory, refresh: Bool = false
    ) async {
        loadTask?.cancel()

        loadTask = Task {
            guard let accountsManager = accountsManager else {
                logger.debug("No accountsManager available")
                return
            }

            if refresh {
                if !Task.isCancelled {
                    isRefreshing = true
                }
            } else {
                if !Task.isCancelled {
                    isLoading = true
                }
            }

            defer {
                if !Task.isCancelled {
                    isLoading = false
                    isRefreshing = false
                }
            }

            do {
                // Try cache first if not refreshing
                if !refresh,
                    let cached = try? await cacheService.retrieveItem(
                        id: id, category: category)
                {
                    if !Task.isCancelled {
                        item = cached
                        // Refresh in background
                        Task {
                            await refreshItemInBackground(
                                id: id, category: category)
                        }
                        return
                    }
                }

                guard !Task.isCancelled else { return }

                let endpoint = ItemEndpoint.make(id: id, category: category)
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: ItemSchema.make(category: category))

                if !Task.isCancelled {
                    item = result
                    try? await cacheService.cacheItem(
                        result, id: id, category: category)
                }

            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error(
                        "Failed to load item: \(error.localizedDescription)")
                }
            }
        }

        await loadTask?.value
    }

    func getKeyMetadata(for item: (any ItemProtocol)?) -> [(String, String)] {
        guard let item = item else { return [] }

        var metadata: [(String, String)] = []

        switch item {
        case let book as EditionSchema:
            if !book.author.isEmpty {
                metadata.append(("Author", book.author.joined(separator: ", ")))
            }
            if let pubYear = book.pubYear {
                metadata.append(("Published", String(pubYear)))
            }
            if let isbn = book.isbn {
                metadata.append(("ISBN", isbn))
            }

        case let movie as MovieSchema:
            if !movie.director.isEmpty {
                metadata.append(
                    ("Director", movie.director.joined(separator: ", ")))
            }
            if let year = movie.year {
                metadata.append(("Year", String(year)))
            }
            if !movie.genre.isEmpty {
                metadata.append(("Genre", movie.genre.joined(separator: ", ")))
            }

        // Add cases for other item types...

        default:
            break
        }

        return metadata
    }

    private func extractUUID(from id: String) -> String {
        if let url = URL(string: id), url.pathComponents.count >= 3 {
            // Return last path component as UUID
            return url.pathComponents.last ?? id
        }
        return id
    }

    private func refreshItemInBackground(id: String, category: ItemCategory)
        async
    {
        guard let accountsManager = accountsManager else { return }

        do {
            let endpoint = ItemEndpoint.make(id: id, category: category)
            let result = try await accountsManager.currentClient.fetch(
                endpoint, type: ItemSchema.make(category: category))
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

    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
}
