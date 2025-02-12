//
//  Cache.swift
//  NeoDB
//
//  Created by citron on 1/20/25.
//

import Foundation
import Cache

/// A unified caching system for the NeoDB app
extension CacheService {
    /// Cache keys for different types of data
    enum Keys {
        // Items
        static func item(id: String) -> String {
            "item_\(id)"
        }

        static func itemPosts(id: String, type: ItemPostType) -> String {
            "itemPosts_\(id)_\(type.rawValue)"
        }
        
        // User related
        static func currentUser(key: String) -> String {
            "currentUser_\(key)"
        }
        
        // Marks related
        static func mark(itemID: String, accountID: String) -> String {
            "mark_\(accountID)_\(itemID)"
        }
        
        // Library related
        static func library(key: String, shelfType: ShelfType, category: ItemCategory.shelfAvailable) -> String {
            "library_\(key)_\(shelfType.rawValue)_\(category.rawValue)"
        }
        
        // Gallery related
        static func gallery(instance: String? = nil) -> String {
            "gallery_\(instance ?? "default")"
        }

        static func gallery(instance: String = "default.instance", category: ItemCategory.galleryCategory) -> String {
            "gallery_\(instance)_\(category.rawValue)"
        }
        
        // Search related
        static func search(query: String, page: Int, instance: String? = nil) -> String {
            let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return "search_\(instance ?? "default")_\(normalizedQuery)_\(page)"
        }

        static func timelines(key: String) -> String {
            "timelines_\(key)"
        }
    }
    
    // MARK: - Item Caching
    
    func cacheItem(_ item: any ItemProtocol, id: String, category: ItemCategory) async throws {
        let key = Keys.item(id: id)
        switch category {
        case .book:
            if let book = item as? EditionSchema {
                try await cache(book, forKey: key, type: EditionSchema.self)
            }
        case .movie:
            if let movie = item as? MovieSchema {
                try await cache(movie, forKey: key, type: MovieSchema.self)
            }
        case .tv:
            if let show = item as? TVShowSchema {
                try await cache(show, forKey: key, type: TVShowSchema.self)
            }
        case .tvSeason:
            if let season = item as? TVShowSchema {
                try await cache(season, forKey: key, type: TVShowSchema.self)
            }
        case .tvEpisode:
            if let episode = item as? TVShowSchema {
                try await cache(episode, forKey: key, type: TVShowSchema.self)
            }
        case .music:
            if let album = item as? AlbumSchema {
                try await cache(album, forKey: key, type: AlbumSchema.self)
            }
        case .game:
            if let game = item as? GameSchema {
                try await cache(game, forKey: key, type: GameSchema.self)
            }
        case .podcast:
            if let podcast = item as? PodcastSchema {
                try await cache(podcast, forKey: key, type: PodcastSchema.self)
            }
        case .performance:
            if let performance = item as? PerformanceSchema {
                try await cache(performance, forKey: key, type: PerformanceSchema.self)
            }
        case .performanceProduction:
            if let production = item as? PerformanceProductionSchema {
                try await cache(production, forKey: key, type: PerformanceProductionSchema.self)
            }
        default:
            break
        }
    }
    
    func retrieveItem(id: String, category: ItemCategory) async throws -> (any ItemProtocol)? {
        let key = Keys.item(id: id)
        let type = ItemSchema.makeType(category: category)
        return try await retrieve(forKey: key, type: type)
    }
    
    func removeItem(id: String, category: ItemCategory) async throws {
        let key = Keys.item(id: id)
        let type = ItemSchema.makeType(category: category)
        try await remove(forKey: key, type: type)
    }

    // MARK: - Item Posts Caching

    func cacheItemPosts(_ posts: [NeoDBPost], id: String, type: ItemPostType) async throws {
        let key = Keys.itemPosts(id: id, type: type)
        try await cache(posts, forKey: key, type: [NeoDBPost].self)
    }

    func retrieveItemPosts(id: String, type: ItemPostType) async throws -> [NeoDBPost]? {
        let key = Keys.itemPosts(id: id, type: type)
        return try await retrieve(forKey: key, type: [NeoDBPost].self)
    }
    
    func removeItemPosts(id: String, type: ItemPostType) async throws {
        let key = Keys.itemPosts(id: id, type: type)
        try await remove(forKey: key, type: [NeoDBPost].self)
    }
    
    // MARK: - User Caching
    
    func cacheUser(_ user: User, key: String) async throws {
        let key = Keys.currentUser(key: key)
        try await cache(user, forKey: key, type: User.self)
    }
    
    func retrieveUser(key: String) async throws -> User? {
        let key = Keys.currentUser(key: key)
        return try await retrieve(forKey: key, type: User.self)
    }
    
    func removeUser(key: String) async throws {
        let key = Keys.currentUser(key: key)
        try await remove(forKey: key, type: User.self)
    }
    
    // MARK: - Marks Caching
    
    func cacheMark(_ mark: MarkSchema, accountID: String) async throws {
        let key = Keys.mark(itemID: mark.item.id, accountID: accountID)
        try await cache(mark, forKey: key, type: MarkSchema.self)
    }

    func retrieveMark(itemID: String, accountID: String) async throws -> MarkSchema? {
        let key = Keys.mark(itemID: itemID, accountID: accountID)
        return try await retrieve(forKey: key, type: MarkSchema.self)
    }
    
    func removeMark(itemID: String, accountID: String) async throws {
        let key = Keys.mark(itemID: itemID, accountID: accountID)
        try await remove(forKey: key, type: MarkSchema.self)
    }
    
    // MARK: - Library Caching
    
    func cacheLibrary(_ library: PagedMarkSchema, key: String, shelfType: ShelfType, category: ItemCategory.shelfAvailable) async throws {
        let key = Keys.library(key: key, shelfType: shelfType, category: category)
        try await cache(library, forKey: key, type: PagedMarkSchema.self)
    }

    func retrieveLibrary(key: String, shelfType: ShelfType, category: ItemCategory.shelfAvailable) async throws -> PagedMarkSchema? {
        let key = Keys.library(key: key, shelfType: shelfType, category: category)
        return try await retrieve(forKey: key, type: PagedMarkSchema.self)
    }
    
    func removeLibrary(key: String, shelfType: ShelfType, category: ItemCategory.shelfAvailable) async throws {
        let key = Keys.library(key: key, shelfType: shelfType, category: category)
        try await remove(forKey: key, type: PagedMarkSchema.self)
    }
    
    // MARK: - Gallery Caching
    
    func cacheGallery(galleryResult: [GalleryResult], instance: String? = nil) async throws {
        let key = Keys.gallery(instance: instance)
        try await cache(galleryResult, forKey: key, type: [GalleryResult].self)
    }

    func retrieveGallery(instance: String? = nil) async throws -> [GalleryResult]? {
        let key = Keys.gallery(instance: instance)
        return try await retrieve(forKey: key, type: [GalleryResult].self)
    }

    func removeGallery(instance: String? = nil) async throws {
        let key = Keys.gallery(instance: instance)
        try await remove(forKey: key, type: [GalleryResult].self)
    }

    func cacheGallery(_ gallery: TrendingItemResult, category: ItemCategory.galleryCategory, instance: String) async throws {
        let key = Keys.gallery(instance: instance, category: category)
        try await cache(gallery, forKey: key, type: TrendingItemResult.self)
    }

    func retrieveGallery(category: ItemCategory.galleryCategory, instance: String) async throws -> TrendingItemResult? {
        let key = Keys.gallery(instance: instance, category: category)
        return try await retrieve(forKey: key, type: TrendingItemResult.self)
    }

    func removeGallery(category: ItemCategory.galleryCategory, instance: String) async throws {
        let key = Keys.gallery(instance: instance, category: category)
        try await remove(forKey: key, type: TrendingItemResult.self)
    }
    
    // MARK: - Timelines Caching

    func cacheTimelines(_ timelines: [MastodonStatus], key: String) async throws {
        let key = Keys.timelines(key: key)
        try await cache(timelines, forKey: key, type: [MastodonStatus].self)
    }

    func retrieveTimelines(key: String) async throws -> [MastodonStatus]? {
        let key = Keys.timelines(key: key)
        return try await retrieve(forKey: key, type: [MastodonStatus].self)
    }

    func removeTimelines(key: String) async throws {
        let key = Keys.timelines(key: key)
        try await remove(forKey: key, type: [MastodonStatus].self)
    }

    // MARK: - Search Caching
    
    func cacheSearch(_ result: SearchResult, query: String, page: Int, instance: String? = nil) async throws {
        let key = Keys.search(query: query, page: page, instance: instance)
        try await cache(result, forKey: key, type: SearchResult.self)
    }
    
    func retrieveSearch(query: String, page: Int, instance: String? = nil) async throws -> SearchResult? {
        let key = Keys.search(query: query, page: page, instance: instance)
        return try await retrieve(forKey: key, type: SearchResult.self)
    }
    
    func removeSearch(query: String, page: Int, instance: String? = nil) async throws {
        let key = Keys.search(query: query, page: page, instance: instance)
        try await remove(forKey: key, type: SearchResult.self)
    }
}

