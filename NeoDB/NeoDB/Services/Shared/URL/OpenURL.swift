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
    private static let neodbIdentifier = "~neodb~"
    
    static func handleItemURL(_ url: URL, completion: @escaping (RouterDestination?) -> Void) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.path.contains(neodbIdentifier) else {
            logger.debug("Not a NeoDB URL: \(url.absoluteString)")
            completion(nil)
            return
        }
        
        // Remove leading slash and split path
        let path = components.path.dropFirst()
        let pathComponents = path.split(separator: "/").map(String.init)
        
        // Verify we have ~neodb~/type/id format
        guard pathComponents.count >= 3,
              pathComponents[0] == neodbIdentifier else {
            logger.debug("Invalid NeoDB URL format: \(components.path)")
            completion(nil)
            return
        }
        
        let type = pathComponents[1]
        let id = pathComponents[2]
        let category = categoryFromType(type)
        
        logger.debug("Processing NeoDB URL - type: \(type), id: \(id)")
        
        // Create a temporary ItemSchema
        let tempItem = ItemSchema(
            id: id,
            type: type,
            uuid: id,
            url: url.absoluteString,
            apiUrl: "\(components.scheme ?? "https")://\(components.host ?? "")/api/",
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
            brief: type
        )
        
        logger.debug("Created ItemSchema for \(category.rawValue)")
        completion(.itemDetailWithItem(item: tempItem))
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

