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
        URLHandler.handleItemURL(url) { destination in
            if let destination = destination {
                router.navigate(to: destination)
            } else {
                openURL(url)
            }
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
