//
//  OpenURL.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog

class URLHandler {
    private static let logger = Logger.services.urlHandler
    
    static func handleNeoDBURL(_ url: URL, completion: @escaping (RouterDestination?) -> Void) {
        guard let host = url.host, host == "neodb.social" else {
            completion(nil)
            return
        }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 4 else {
            completion(nil)
            return
        }
        
        logger.debug("Processing URL: \(url.absoluteString)")
        logger.debug("Path components: \(pathComponents)")
        
        // Parse NeoDB URL pattern: /~username~/type/id
        // or /~username~/type/subtype/id for TV seasons and episodes
        if pathComponents[1].hasPrefix("~"), pathComponents[1].hasSuffix("~") {
            let type = pathComponents[2]
            let id: String
            let itemType: String
            let category: ItemCategory
            
            if type == "tv" && pathComponents.count >= 5 {
                // Handle TV seasons and episodes
                let subtype = pathComponents[3] // "season" or "episode"
                id = pathComponents[4]
                itemType = subtype
                category = categoryFromType(subtype)
                logger.debug("TV content - type: \(type), subtype: \(subtype), id: \(id)")
            } else {
                id = pathComponents[3]
                itemType = type
                category = categoryFromType(type)
                logger.debug("Regular content - type: \(type), id: \(id)")
            }
            
            // Create a temporary ItemSchema
            let tempItem = ItemSchema(
                id: "",
                type: "",
                uuid: "",
                url: url.absoluteString,
                apiUrl: "https://neodb.social/api/",
                category: category,
                parentUuid: nil,
                displayTitle: id,
                externalResources: nil,
                title: id,
                description: url.absoluteString,
                localizedTitle: nil,
                localizedDescription: nil,
                coverImageUrl: nil,
                rating: nil,
                ratingCount: nil,
                brief: itemType
            )
            
            logger.debug("Created ItemSchema - type: \(tempItem.type), category: \(tempItem.category.rawValue)")
            completion(.itemDetailWithItem(item: tempItem))
        } else {
            completion(nil)
        }
    }
    
    private static func categoryFromType(_ type: String) -> ItemCategory {
        switch type {
        case "movie":
            return .movie
        case "book":
            return .book
        case "tv":
            return .tv
        case "season":
            return .tvSeason
        case "episode":
            return .tvEpisode
        case "game":
            return .game
        case "album":
            return .music
        case "podcast":
            return .podcast
        case "performance":
            return .performance
        default:
            return .book // Default fallback
        }
    }
}

