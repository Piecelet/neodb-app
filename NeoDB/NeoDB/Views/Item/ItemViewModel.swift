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
    
    func loadItemDetail(id: String, category: ItemCategory, refresh: Bool = false) async {
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
                if !refresh, let cached = try? await getCachedItem(id: id, category: category) {
                    if !Task.isCancelled {
                        item = cached
                        // Refresh in background
                        Task {
                            await refreshItemInBackground(id: id, category: category)
                        }
                        return
                    }
                }
                
                guard !Task.isCancelled else { return }
                
                let endpoint = ItemEndpoint.make(id: id, category: category)
                let result = try await accountsManager.currentClient.fetch(endpoint, type: ItemSchema.make(category: category))
                
                if !Task.isCancelled {
                    item = result
                    try? await cacheItem(result, id: id, category: category)
                }
                
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error("Failed to load item: \(error.localizedDescription)")
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
                metadata.append(("Director", movie.director.joined(separator: ", ")))
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
    
    private func getCachedItem(id: String, category: ItemCategory) async throws -> (any ItemProtocol)? {
        let cacheKey = "\(id)_\(category.rawValue)"
        let type = ItemSchema.make(category: category)
        return try await cacheService.retrieve(forKey: cacheKey, type: type)
    }
    
    private func cacheItem(_ item: any ItemProtocol, id: String, category: ItemCategory) async throws {
        let cacheKey = "\(id)_\(category.rawValue)"
        switch category {
        case .book:
            if let book = item as? EditionSchema {
                try await cacheService.cache(book, forKey: cacheKey, type: EditionSchema.self)
            }
        case .movie:
            if let movie = item as? MovieSchema {
                try await cacheService.cache(movie, forKey: cacheKey, type: MovieSchema.self)
            }
        case .tv:
            if let show = item as? TVShowSchema {
                try await cacheService.cache(show, forKey: cacheKey, type: TVShowSchema.self)
            }
        case .tvSeason:
            if let season = item as? TVSeasonSchema {
                try await cacheService.cache(season, forKey: cacheKey, type: TVSeasonSchema.self)
            }
        case .tvEpisode:
            if let episode = item as? TVEpisodeSchema {
                try await cacheService.cache(episode, forKey: cacheKey, type: TVEpisodeSchema.self)
            }
        case .music:
            if let album = item as? AlbumSchema {
                try await cacheService.cache(album, forKey: cacheKey, type: AlbumSchema.self)
            }
        case .game:
            if let game = item as? GameSchema {
                try await cacheService.cache(game, forKey: cacheKey, type: GameSchema.self)
            }
        case .podcast:
            if let podcast = item as? PodcastSchema {
                try await cacheService.cache(podcast, forKey: cacheKey, type: PodcastSchema.self)
            }
        case .performance:
            if let performance = item as? PerformanceSchema {
                try await cacheService.cache(performance, forKey: cacheKey, type: PerformanceSchema.self)
            }
        case .performanceProduction:
            if let production = item as? PerformanceProductionSchema {
                try await cacheService.cache(production, forKey: cacheKey, type: PerformanceProductionSchema.self)
            }
        default:
            break
        }
    }
    
    private func refreshItemInBackground(id: String, category: ItemCategory) async {
        guard let accountsManager = accountsManager else { return }
        
        do {
            let endpoint = ItemEndpoint.make(id: id, category: category)
            let result = try await accountsManager.currentClient.fetch(endpoint, type: ItemSchema.make(category: category))
            try? await cacheItem(result, id: id, category: category)
            
            if !Task.isCancelled {
                item = result
            }
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription)")
        }
    }
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 
