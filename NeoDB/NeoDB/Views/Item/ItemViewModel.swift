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
    var originalTitle: String {
        switch item {
        case let book as EditionSchema:
            return book.origTitle ?? ""
        case let movie as MovieSchema:
            if let year = movie.year {
                return "\(movie.origTitle ?? "") (\(year))"
            }
            return movie.origTitle ?? ""
        case let tv as TVShowSchema:
            return tv.origTitle ?? ""
        case let performance as PerformanceSchema:
            return performance.origTitle ?? ""
        default:
            return ""
        }
    }
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

    var allMetadata: [String] {
        guard let item else { return [] }

        var metadata: [String] = []

        switch item {
        case let book as EditionSchema:
            if !book.author.isEmpty {
                metadata.append("Author: \(book.author.joined(separator: ", "))")
            }
            if !book.translator.isEmpty {
                metadata.append("Translator: \(book.translator.joined(separator: ", "))")
            }
            if let subtitle = book.subtitle {
                metadata.append("Subtitle: \(subtitle)")
            }
            if let origTitle = book.origTitle {
                metadata.append("Original Title: \(origTitle)")
            }
            if !book.language.isEmpty {
                metadata.append("Language: \(book.language.joined(separator: ", "))")
            }
            if let pubHouse = book.pubHouse {
                metadata.append("Publisher: \(pubHouse)")
            }
            if let pubYear = book.pubYear {
                metadata.append("Publication Year: \(pubYear)")
            }
            if let pubMonth = book.pubMonth {
                metadata.append("Publication Month: \(pubMonth)")
            }
            if let binding = book.binding {
                metadata.append("Binding: \(binding)")
            }
            if let price = book.price {
                metadata.append("Price: \(price)")
            }
            if let pages = book.pages {
                metadata.append("Pages: \(pages)")
            }
            if let series = book.series {
                metadata.append("Series: \(series)")
            }
            if let imprint = book.imprint {
                metadata.append("Imprint: \(imprint)")
            }
            if let isbn = book.isbn {
                metadata.append("ISBN: \(isbn)")
            }
            
        case let movie as MovieSchema:
            if let origTitle = movie.origTitle {
                metadata.append("Original Title: \(origTitle)")
            }
            if !movie.otherTitle.isEmpty {
                metadata.append("Other Titles: \(movie.otherTitle.joined(separator: ", "))")
            }
            if !movie.director.isEmpty {
                metadata.append("Director: \(movie.director.joined(separator: ", "))")
            }
            if !movie.playwright.isEmpty {
                metadata.append("Playwright: \(movie.playwright.joined(separator: ", "))")
            }
            if !movie.actor.isEmpty {
                metadata.append("Actors: \(movie.actor.joined(separator: ", "))")
            }
            if !movie.genre.isEmpty {
                metadata.append("Genre: \(movie.genre.joined(separator: ", "))")
            }
            if !movie.language.isEmpty {
                metadata.append("Language: \(movie.language.joined(separator: ", "))")
            }
            if !movie.area.isEmpty {
                metadata.append("Area: \(movie.area.joined(separator: ", "))")
            }
            if let year = movie.year {
                metadata.append("Year: \(year)")
            }
            if let site = movie.site {
                metadata.append("Website: \(site)")
            }
            if let duration = movie.duration {
                metadata.append("Duration: \(duration)")
            }
            if let imdb = movie.imdb {
                metadata.append("IMDB: \(imdb)")
            }
            
        case let tv as TVShowSchema:
            if let origTitle = tv.origTitle {
                metadata.append("Original Title: \(origTitle)")
            }
            if let otherTitle = tv.otherTitle, !otherTitle.isEmpty {
                metadata.append("Other Titles: \(otherTitle.joined(separator: ", "))")
            }
            if let director = tv.director, !director.isEmpty {
                metadata.append("Director: \(director.joined(separator: ", "))")
            }
            if let playwright = tv.playwright, !playwright.isEmpty {
                metadata.append("Playwright: \(playwright.joined(separator: ", "))")
            }
            if let actor = tv.actor, !actor.isEmpty {
                metadata.append("Actors: \(actor.joined(separator: ", "))")
            }
            if let genre = tv.genre, !genre.isEmpty {
                metadata.append("Genre: \(genre.joined(separator: ", "))")
            }
            if let language = tv.language, !language.isEmpty {
                metadata.append("Language: \(language.joined(separator: ", "))")
            }
            if let area = tv.area, !area.isEmpty {
                metadata.append("Area: \(area.joined(separator: ", "))")
            }
            if let year = tv.year {
                metadata.append("Year: \(year)")
            }
            if let site = tv.site {
                metadata.append("Website: \(site)")
            }
            if let seasonCount = tv.seasonCount {
                metadata.append("Seasons: \(seasonCount)")
            }
            if let episodeCount = tv.episodeCount {
                metadata.append("Episodes: \(episodeCount)")
            }
            if let imdb = tv.imdb {
                metadata.append("IMDB: \(imdb)")
            }
            
        case let album as AlbumSchema:
            if !album.otherTitle.isEmpty {
                metadata.append("Other Titles: \(album.otherTitle.joined(separator: ", "))")
            }
            if !album.genre.isEmpty {
                metadata.append("Genre: \(album.genre.joined(separator: ", "))")
            }
            if !album.artist.isEmpty {
                metadata.append("Artists: \(album.artist.joined(separator: ", "))")
            }
            if !album.company.isEmpty {
                metadata.append("Company: \(album.company.joined(separator: ", "))")
            }
            if let duration = album.duration {
                metadata.append("Duration: \(duration) minutes")
            }
            if let releaseDate = album.releaseDate {
                metadata.append("Release Date: \(releaseDate)")
            }
            if let trackList = album.trackList {
                metadata.append("Track List: \(trackList)")
            }
            if let barcode = album.barcode {
                metadata.append("Barcode: \(barcode)")
            }
            
        case let game as GameSchema:
            if !game.genre.isEmpty {
                metadata.append("Genre: \(game.genre.joined(separator: ", "))")
            }
            if !game.developer.isEmpty {
                metadata.append("Developer: \(game.developer.joined(separator: ", "))")
            }
            if !game.publisher.isEmpty {
                metadata.append("Publisher: \(game.publisher.joined(separator: ", "))")
            }
            if !game.platform.isEmpty {
                metadata.append("Platform: \(game.platform.joined(separator: ", "))")
            }
            if let releaseType = game.releaseType {
                metadata.append("Release Type: \(releaseType)")
            }
            if let releaseDate = game.releaseDate {
                metadata.append("Release Date: \(releaseDate)")
            }
            if let officialSite = game.officialSite {
                metadata.append("Official Site: \(officialSite)")
            }
            
        case let podcast as PodcastSchema:
            if !podcast.host.isEmpty {
                metadata.append("Host: \(podcast.host.joined(separator: ", "))")
            }
            if !podcast.genre.isEmpty {
                metadata.append("Genre: \(podcast.genre.joined(separator: ", "))")
            }
            if !podcast.language.isEmpty {
                metadata.append("Language: \(podcast.language.joined(separator: ", "))")
            }
            if let episodeCount = podcast.episodeCount {
                metadata.append("Episodes: \(episodeCount)")
            }
            if let lastEpisodeDate = podcast.lastEpisodeDate {
                metadata.append("Last Episode: \(lastEpisodeDate)")
            }
            if let rssUrl = podcast.rssUrl {
                metadata.append("RSS URL: \(rssUrl)")
            }
            if let websiteUrl = podcast.websiteUrl {
                metadata.append("Website: \(websiteUrl)")
            }
            
        default:
            break
        }

        return metadata.filter { !$0.isEmpty }
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
            
            updateLoadingState(refresh: refresh)
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                    isRefreshing = false
                }
            }
            
            do {
                if !refresh,
                    let cached = try? await cacheService.retrieveItem(
                        id: id, category: category, instance: accountsManager.currentAccount.instance)
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
                result, id: id, category: category, instance: accountsManager?.currentAccount.instance)
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
        // let cacheKey = "mark_\(itemId)"
        return try await cacheService.retrieveMark(
            key: accountsManager?.currentAccount.id ?? "default", itemUUID: itemId)
    }

    private func cacheMark(_ mark: MarkSchema, itemId: String) async throws {
        try await cacheService.cacheMark(
            mark, key: accountsManager?.currentAccount.id ?? "default", itemUUID: itemId, instance: accountsManager?.currentAccount.instance)
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
                result, id: id, category: category, instance: accountsManager.currentAccount.instance)
            
            if !Task.isCancelled {
                item = result
            }
        } catch {
            logger.error(
                "Background refresh failed: \(error.localizedDescription)")
        }
    }
} 
