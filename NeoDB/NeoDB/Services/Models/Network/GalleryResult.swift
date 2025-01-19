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

    var displayTitle: String {
        switch name {
        case "trending_book":
            return "Books"
        case "trending_movie":
            return "Movies"
        case "trending_tv":
            return "TV Shows"
        case "trending_game":
            return "Games"
        case "trending_music":
            return "Music"
        case "trending_podcast":
            return "Podcasts"
        case "trending_performance":
            return "Performances"
        default:
            return name
        }
    }
}
