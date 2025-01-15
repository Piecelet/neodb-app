//
//  HTMLContentView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import HTML2Markdown
import MarkdownUI
import OSLog

struct HTMLContentView: View {
    let htmlContent: String
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router
    private let logger = Logger.htmlContent
    
    var body: some View {
        if let markdown = convertHTMLToMarkdown(htmlContent) {
            Markdown(markdown)
                .markdownTheme(.gitHub)
                .textSelection(.enabled)
                .padding(.vertical, 4)
                .environment(\.openURL, OpenURLAction { url in
                    handleURL(url)
                    return .handled
                })
        } else {
            Text(htmlContent)
                .textSelection(.enabled)
        }
    }
    
    private func handleURL(_ url: URL) {
        guard let host = url.host, host == "neodb.social" else {
            openURL(url)
            return
        }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 4 else {
            openURL(url)
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
                category = categoryFromType(subtype) // Use subtype for category
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
                url: "",
                apiUrl: nil,
                category: nil,
                parentUuid: nil,
                displayTitle: id,
                externalResources: itemType,
                title: id,
                description: url.absoluteString,
                localizedTitle: "",
                localizedDescription: category,
                coverImageUrl: nil,
                rating: "",
                ratingCount: nil,
                brief: nil
            )
            
            logger.debug("Created ItemSchema - type: \(tempItem.type), category: \(tempItem.category.rawValue)")
            router.navigate(to: .itemDetailWithItem(item: tempItem))
        } else {
            openURL(url)
        }
    }
    
    private func categoryFromType(_ type: String) -> ItemCategory {
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
    
    private func convertHTMLToMarkdown(_ html: String) -> String? {
        // Remove extra newlines and spaces
        let cleanedHTML = html.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        do {
            let dom = try HTMLParser().parse(html: cleanedHTML)
            // Use bullets for unordered lists for better SwiftUI Text compatibility
            let markdown = dom.markdownFormatted(options: .unorderedListBullets)
            return markdown
        } catch {
            print("Error parsing HTML: \(error)")
            return nil
        }
    }
} 
