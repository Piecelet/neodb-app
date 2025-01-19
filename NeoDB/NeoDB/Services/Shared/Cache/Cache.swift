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
        
        // User related
        static func user(instance: String) -> String {
            "\(instance)_user"
        }
        
        // Marks related
        static func marks(instance: String, shelfType: ShelfType?) -> String {
            if let type = shelfType {
                return "marks_\(instance)_\(type.rawValue)"
            }
            return "marks_\(instance)"
        }
        
        // Gallery related
        static func gallery(instance: String) -> String {
            "gallery_\(instance)"
        }
    }
    
    // MARK: - Item Caching
    
    func cacheItem(_ item: any ItemProtocol, id: String, category: ItemCategory) async throws {
        let uuid = id.components(separatedBy: "/").last ?? id
        let key = Keys.item(id: uuid)
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
            if let season = item as? TVSeasonSchema {
                try await cache(season, forKey: key, type: TVSeasonSchema.self)
            }
        case .tvEpisode:
            if let episode = item as? TVEpisodeSchema {
                try await cache(episode, forKey: key, type: TVEpisodeSchema.self)
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
        let type = ItemSchema.make(category: category)
        return try await retrieve(forKey: key, type: type)
    }
    
    func removeItem(id: String, category: ItemCategory) async throws {
        let key = Keys.item(id: id)
        let type = ItemSchema.make(category: category)
        try await remove(forKey: key, type: type)
    }
    
    // MARK: - User Caching
    
    func cacheUser(_ user: User, instance: String) async throws {
        let key = Keys.user(instance: instance)
        try await cache(user, forKey: key, type: User.self)
    }
    
    func retrieveUser(instance: String) async throws -> User? {
        let key = Keys.user(instance: instance)
        return try await retrieve(forKey: key, type: User.self)
    }
    
    func removeUser(instance: String) async throws {
        let key = Keys.user(instance: instance)
        try await remove(forKey: key, type: User.self)
    }
    
    // MARK: - Marks Caching
    
    func cacheMarks(_ marks: [MarkSchema], instance: String, shelfType: ShelfType?) async throws {
        let key = Keys.marks(instance: instance, shelfType: shelfType)
        try await cache(marks, forKey: key, type: [MarkSchema].self)
    }
    
    func retrieveMarks(instance: String, shelfType: ShelfType?) async throws -> [MarkSchema]? {
        let key = Keys.marks(instance: instance, shelfType: shelfType)
        return try await retrieve(forKey: key, type: [MarkSchema].self)
    }
    
    func removeMarks(instance: String, shelfType: ShelfType?) async throws {
        let key = Keys.marks(instance: instance, shelfType: shelfType)
        try await remove(forKey: key, type: [MarkSchema].self)
    }
    
    // MARK: - Gallery Caching
    
    func cacheGallery(_ gallery: [GalleryResult], instance: String) async throws {
        let key = Keys.gallery(instance: instance)
        try await cache(gallery, forKey: key, type: [GalleryResult].self)
    }
    
    func retrieveGallery(instance: String) async throws -> [GalleryResult]? {
        let key = Keys.gallery(instance: instance)
        return try await retrieve(forKey: key, type: [GalleryResult].self)
    }
    
    func removeGallery(instance: String) async throws {
        let key = Keys.gallery(instance: instance)
        try await remove(forKey: key, type: [GalleryResult].self)
    }
}

