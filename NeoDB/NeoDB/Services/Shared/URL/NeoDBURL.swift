//
//  NeoDBURL.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import Foundation
import OSLog
import SwiftSoup

class NeoDBURL {
    private static let logger = Logger.services.url.neodbURL
    private static let neodbItemIdentifier = "~neodb~"
    private static let isDebugLoggingEnabled = false
    
    private static func log(_ message: String) {
        guard isDebugLoggingEnabled else { return }
        logger.debug("\(message)")
    }
    
    static func parseItemURL(_ url: URL) async -> (any ItemProtocol)? {
        guard
            let components = URLComponents(
                url: url, resolvingAgainstBaseURL: true),
            components.path.contains(neodbItemIdentifier)
        else {
            log("Not a NeoDB URL: \(url.absoluteString)")
            return nil
        }

        // Remove leading slash and split path
        let path = components.path.dropFirst()
        let pathComponents = path.split(separator: "/").map(String.init)

        // Verify we have ~neodb~/type/id format
        guard pathComponents.count >= 3,
            pathComponents[0] == neodbItemIdentifier
        else {
            log("Invalid NeoDB URL format: \(components.path)")
            return nil
        }

        let type = pathComponents[1]
        var id = pathComponents[2]

        // Handle special cases for tv seasons and episodes
        let category: ItemCategory
        if type == "podcast" {
            return await parseItemPodcastURL(url)
        } else if type == "tv" && pathComponents.count >= 4 {
            switch pathComponents[2] {
            case "season":
                category = .tvSeason
            case "episode":
                category = .tvEpisode
            default:
                category = .tv
            }
            id = pathComponents[3]
        } else if type == "album" {
            category = .music
        } else if type == "performance" && pathComponents[2] == "production" {
            category = .performanceProduction
            id = pathComponents[3]
        } else if let itemCategory = ItemCategory(rawValue: type) {
            category = itemCategory
        } else {
            log("Unknown item type: \(type), defaulting to book")
            category = .book
        }

        log("Processing NeoDB URL - type: \(type), id: \(id)")

        // Create item URL by removing ~neodb~
        var itemComponents = components
        itemComponents.path = itemComponents.path.replacingOccurrences(
            of: "/\(neodbItemIdentifier)", with: "")

        // Create API URL by replacing ~neodb~ with api
        var apiComponents = components
        apiComponents.path = apiComponents.path.replacingOccurrences(
            of: "/\(neodbItemIdentifier)", with: "/api")

        // Create a temporary ItemSchema
        let urlItem = ItemSchema(
            id: id,
            type: type,
            uuid: id,
            url: itemComponents.url?.absoluteString ?? url.absoluteString,
            apiUrl: apiComponents.url?.absoluteString ?? url.absoluteString,
            category: category,
            parentUuid: nil,
            displayTitle: nil,
            externalResources: nil,
            title: nil,
            description: nil,
            localizedTitle: nil,
            localizedDescription: nil,
            coverImageUrl: nil,
            rating: nil,
            ratingCount: nil,
            brief: type
        )

        log("Created ItemSchema for \(category.rawValue)")
        return urlItem
    }

    static func parseItemPodcastURL(_ url: URL) async -> PodcastSchema? {
        guard
            let components = URLComponents(
                url: url, resolvingAgainstBaseURL: true),
            components.path.contains(neodbItemIdentifier)
        else {
            return nil
        }

        let path = components.path.dropFirst()
        let pathComponents = path.split(separator: "/").map(String.init)

        guard pathComponents.count >= 3,
            pathComponents[0] == neodbItemIdentifier
        else {
            return nil
        }

        var uuid = pathComponents[2]

        if pathComponents.count >= 4 || pathComponents[2] == "episode" {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let html = String(data: data, encoding: .utf8) else {
                    logger.error("Failed to decode HTML from URL: \(url)")
                    return nil
                }
                
                let doc = try SwiftSoup.parse(html)
                if let meta = try doc.select("meta[http-equiv=refresh]").first(),
                   let content = try? meta.attr("content"),
                   content.contains("url=") {
                    let urlPart = content.split(separator: "url=").last.map(String.init) ?? ""
                    let fullURL = "https://\(components.host ?? AppConfig.defaultInstance)\(urlPart)"
                    if let redirectComponents = URLComponents(string: fullURL) {
                        let pathParts = redirectComponents.path.split(separator: "/")
                        if pathParts.count >= 2 && pathParts[0] == "podcast" {
                            uuid = String(pathParts[1])
                            logger.debug("Found podcast UUID from meta refresh: \(uuid)")
                        }
                    }
                }
            } catch {
                logger.error("Failed to load or parse URL: \(error.localizedDescription)")
                return nil
            }
        }

        var itemComponents = components
        itemComponents.path = itemComponents.path.replacingOccurrences(
            of: "/\(neodbItemIdentifier)", with: "")

        var apiComponents = components
        apiComponents.path = apiComponents.path.replacingOccurrences(
            of: "/\(neodbItemIdentifier)", with: "/api")

        return PodcastSchema(
            id: url.absoluteString,
            type: "Podcast",
            uuid: uuid,
            url: itemComponents.path,
            apiUrl: apiComponents.path,
            category: .podcast,
            parentUuid: nil,
            displayTitle: nil,
            externalResources: nil,
            title: nil,
            description: nil,
            localizedTitle: nil,
            localizedDescription: nil,
            coverImageUrl: nil,
            rating: nil,
            ratingCount: nil,
            brief: "",
            host: [],
            genre: [],
            language: [],
            episodeCount: nil,
            lastEpisodeDate: nil,
            rssUrl: nil,
            websiteUrl: nil
        )
    }
}


