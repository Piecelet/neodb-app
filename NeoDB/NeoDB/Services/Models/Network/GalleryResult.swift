//
//  GalleryItems.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

typealias TrendingItemResult = [ItemSchema]

struct GalleryResult: Codable, Identifiable {
    let name: String
    let items: TrendingItemResult
    
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

struct GalleryTrending: Codable, Identifiable, Hashable {
    let category: ItemCategory.galleryCategory
    let items: TrendingItemResult
    
    var id: String {
        category.rawValue
    }
}
