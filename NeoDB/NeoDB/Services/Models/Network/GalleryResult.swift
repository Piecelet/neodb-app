//
//  GalleryItems.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct GalleryResult: Codable, Identifiable {
    let name: String
    let items: [ItemSchema]
    
    var id: String {
        name
    }

    var itemCategory: ItemCategory? {
        switch name {
        case "trending_book":
            return .book
        case "trending_movie":
            return .movie
        case "trending_tv":
            return .tv
        case "trending_game":
            return .game
        case "trending_music":
            return .music
        case "trending_podcast":
            return .podcast
        case "trending_performance":
            return .performance
        default:
            return nil
        }
    }

    var displayTitle: String {
        return itemCategory?.displayName ?? name
    }
}

typealias TrendingGalleryResult = [(any ItemProtocol)]

extension TrendingGalleryResult {
    static func makeType(category: ItemCategory.galleryCategory) -> Any.Type {
        switch category {
        case .book:
            return [EditionSchema].self
        case .movie:
            return [MovieSchema].self
        case .tv:
            return [TVShowSchema].self
        case .music:
            return [AlbumSchema].self
        case .game:
            return [GameSchema].self
        case .podcast:
            return [PodcastSchema].self
        case .collection:
            return [ItemSchema].self
        }
    }
}
