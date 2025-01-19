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
    private var markLoadTask: Task<Void, Never>?

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

    @Published var item: (any ItemProtocol)?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showError = false
    
    // Mark related state
    @Published var mark: MarkSchema?
    @Published var isMarkLoading = false
    
    // Description expansion state
    @Published var isDescriptionExpanded = false

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

    // MARK: - Computed Properties for UI
    var displayTitle: String { item?.displayTitle ?? "" }
    var coverImageURL: URL? { item?.coverImageUrl }
    var rating: String {
        if let rating = item?.rating {
            return String(format: "%.1f", rating)
        }
        return ""
    }
    var ratingCount: String { item?.ratingCount.map(String.init) ?? "0" }
    var description: String { item?.description ?? "" }
    var shelfType: ShelfType? { mark?.shelfType }
    
    var metadata: [String] {
        guard let item = item else { return [] }

        var metadata: [String] = []

        switch item {
        case let book as EditionSchema:
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
        // Add cases for other item types as needed
        default:
            break
        }

        return metadata
    }

    var shareURL: URL? {
        guard let item = item,
            let accountsManager = accountsManager
        else { return nil }
        return ItemURL.makeShareURL(
            for: item, instance: accountsManager.currentAccount.instance)
    }

    // MARK: - User Actions
    func toggleDescription() {
        isDescriptionExpanded.toggle()
    }

    // MARK: - Data Loading
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
    
    // MARK: - Mark Related Functions
    func loadMarkIfNeeded() {
        guard mark == nil,
            let item = item
        else { return }
        loadMark(itemId: item.uuid, refresh: false)
    }

    func refresh() {
        guard let item = item else { return }
        loadMark(itemId: item.uuid, refresh: true)
    }

    private func loadMark(itemId: String, refresh: Bool) {
        markLoadTask?.cancel()

        markLoadTask = Task {
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
                // Try cache first if not refreshing
                if !refresh,
                    let cached = try? await getCachedMark(itemId: itemId)
                {
                    if !Task.isCancelled {
                        mark = cached
                    }
                }

                // Always fetch from network
                let endpoint = MarkEndpoint.get(itemId: itemId)
                let result = try await accountsManager.currentClient.fetch(
                    endpoint, type: MarkSchema.self)

                if !Task.isCancelled {
                    mark = result
                    try? await cacheMark(result, itemId: itemId)
                }
            } catch {
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
                                "Failed to load mark: \(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
        }
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
        markLoadTask?.cancel()
        loadTask = nil
        markLoadTask = nil
    }
}
