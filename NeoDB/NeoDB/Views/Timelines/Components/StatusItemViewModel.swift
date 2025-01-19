//
//  StatusItemViewModel.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import Foundation
import OSLog

@MainActor
class StatusItemViewModel: ObservableObject {
    private let logger = Logger.views.status.item
    private let cacheService = CacheService()
    private var loadTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                loadItemIfNeeded()
            }
        }
    }
    
    @Published var item: any ItemProtocol
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    init(item: any ItemProtocol) {
        self.item = item
    }
    
    private func loadItemIfNeeded() {
        guard accountsManager != nil else { return }
        
        logger.debug("Checking if item needs loading: \(item.id)")
        // Only load if we don't have full details
        guard item.description == nil || item.rating == nil else { 
            logger.debug("Item already has full details")
            return 
        }
        
        loadItem(refresh: false)
    }
    
    func loadItem(refresh: Bool) {
        guard let accountsManager = accountsManager else {
            logger.error("No accountsManager available")
            return
        }
        
        loadTask?.cancel()
        
        loadTask = Task {
            if !Task.isCancelled {
                isLoading = true
                logger.debug("Started loading item: \(item.id)")
            }
            
            defer {
                if !Task.isCancelled {
                    isLoading = false
                }
            }
            
            do {
                // Try cache first if not refreshing
                if !refresh {
                    if let cached = try? await getCachedItem(id: item.id, category: item.category) {
                        if !Task.isCancelled {
                            logger.debug("Using cached item: \(item.id)")
                            item = cached
                            return
                        }
                    }
                }
                
                guard accountsManager.isAuthenticated else {
                    logger.error("Not authenticated")
                    throw NetworkError.unauthorized
                }
                
                // Fetch from network
                let endpoint = ItemEndpoint.make(id: item.id, category: item.category)
                let result = try await accountsManager.currentClient.fetch(endpoint, type: ItemSchema.make(category: item.category))
                
                if !Task.isCancelled {
                    logger.debug("Successfully loaded item: \(item.id)")
                    item = result
                    try? await cacheItem(result, id: item.id, category: item.category)
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.showError = true
                    logger.error("Failed to load item: \(error.localizedDescription)")
                }
            }
        }
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
    
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil
    }
} 
