import SwiftUI
import HTML2Markdown
import MarkdownUI

struct HTMLContentView: View {
    let htmlContent: String
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        if let markdown = convertHTMLToMarkdown(htmlContent) {
            Markdown(markdown)
                .markdownTheme(.gitHub)
                .textSelection(.enabled)
                .padding(.vertical, 4)
        } else {
            Text(htmlContent)
                .textSelection(.enabled)
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