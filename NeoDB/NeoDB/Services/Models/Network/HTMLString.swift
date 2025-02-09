//
//  HTMLString.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//
//  From https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
//

import Foundation
import SwiftSoup
import SwiftUI

private enum CodingKeys: CodingKey {
    case htmlValue, asMarkdown, asRawText, statusesURLs, links
}

struct HTMLString: Codable, Equatable, Hashable, @unchecked Sendable {
    var htmlValue: String = ""
    var asMarkdown: String = ""
    var asRawText: String = ""
    var statusesURLs = [URL]()
    private(set) var links = [Link]()

    var asSafeMarkdownAttributedString: AttributedString = .init()
    
    // 获取第一行（如果包含 ~neodb~）
    var neodbStatusLine: String? {
        let lines = asMarkdown.split(separator: "\n", maxSplits: 1)
        guard let firstLine = lines.first,
              firstLine.contains("~neodb~") else {
            return nil
        }
        return String(firstLine)
    }
    
    // 获取第一行的 AttributedString（如果是 NeoDB 状态行）
    var neodbStatusLineAttributedString: AttributedString? {
        guard let statusLine = neodbStatusLine else {
            return nil
        }
        return (try? AttributedString(markdown: statusLine)) ?? AttributedString(statusLine)
    }
    
    // 获取不包含评分的 NeoDB 状态行
    var neodbStatusLineAttributedStringWithoutRating: AttributedString? {
        guard let statusLine = neodbStatusLine else {
            return nil
        }
        // 移除评分字符
        var text = statusLine
        let ratingPattern = "[🌕🌗🌑]+"
        if let regex = try? NSRegularExpression(pattern: ratingPattern) {
            text = regex.stringByReplacingMatches(
                in: text,
                range: NSRange(text.startIndex..., in: text),
                withTemplate: ""
            )
        }
        return (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
    
    // 获取不包含 NeoDB 状态行的内容
    var asSafeMarkdownAttributedStringWithoutNeoDBStatus: AttributedString {
        var text = asMarkdown
        if neodbStatusLine != nil {
            // 如果存在 NeoDB 状态行，移除第一行（包括换行符）
            if let newlineIndex = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: newlineIndex)...])
            }
        }
        // 移除开头和结尾的换行符，但保留内容中的换行
        text = text.trimmingCharacters(in: .newlines)
        do {
            let options = AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace)
            return try AttributedString(markdown: text, options: options)
        } catch {
            return AttributedString(text)
        }
    }
    
    var asSafeMarkdownAttributedStringWithoutRating: AttributedString {
        var text = asMarkdown
        // 移除评分字符
        let ratingPattern = "[🌕🌗🌑]+"
        if let regex = try? NSRegularExpression(pattern: ratingPattern) {
            text = regex.stringByReplacingMatches(
                in: text,
                range: NSRange(text.startIndex..., in: text),
                withTemplate: ""
            )
        }
        return (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
    
    var rating: Double? {
        // 查找评分字符串
        let ratingPattern = "[🌕🌗🌑]+"
        guard let regex = try? NSRegularExpression(pattern: ratingPattern),
              let match = regex.firstMatch(
                in: asMarkdown,
                range: NSRange(asMarkdown.startIndex..., in: asMarkdown)
              ),
              let range = Range(match.range, in: asMarkdown) else {
            return nil
        }
        
        let ratingString = String(asMarkdown[range])
        
        // 计算评分
        var score = 0.0
        for char in ratingString {
            switch char {
            case "🌕":
                score += 2.0
            case "🌗":
                score += 1.0
            case "🌑":
                score += 0.0
            default:
                continue
            }
        }
        
        return score
    }
    
    private var main_regex: NSRegularExpression?
    private var underscore_regex: NSRegularExpression?
    init(from decoder: Decoder) {
        var alreadyDecoded = false
        do {
            let container = try decoder.singleValueContainer()
            htmlValue = try container.decode(String.self)
        } catch {
            do {
                alreadyDecoded = true
                let container = try decoder.container(keyedBy: CodingKeys.self)
                htmlValue = try container.decode(
                    String.self, forKey: .htmlValue)
                asMarkdown = try container.decode(
                    String.self, forKey: .asMarkdown)
                asRawText = try container.decode(
                    String.self, forKey: .asRawText)
                statusesURLs = try container.decode(
                    [URL].self, forKey: .statusesURLs)
                links = try container.decode([Link].self, forKey: .links)
            } catch {
                htmlValue = ""
            }
        }

        if !alreadyDecoded {
            // https://daringfireball.net/projects/markdown/syntax
            // Pre-escape \ ` _ * ~ and [ as these are the only
            // characters the markdown parser uses when it renders
            // to attributed text. Note that ~ for strikethrough is
            // not documented in the syntax docs but is used by
            // AttributedString.
            main_regex = try? NSRegularExpression(
                pattern: "([\\*\\`\\~\\[\\\\])", options: .caseInsensitive)
            // don't escape underscores that are between colons, they are most likely custom emoji
            underscore_regex = try? NSRegularExpression(
                pattern: "(?!\\B:[^:]*)(_)(?![^:]*:\\B)",
                options: .caseInsensitive)

            asMarkdown = ""
            do {
                let document: Document = try SwiftSoup.parse(htmlValue)
                var listCounters: [Int] = []
                handleNode(node: document, listCounters: &listCounters)

                document.outputSettings(
                    OutputSettings().prettyPrint(pretty: false))
                try document.select("br").after("\n")
                try document.select("p").after("\n\n")
                let html = try document.html()
                var text =
                    try SwiftSoup.clean(
                        html, "", Whitelist.none(),
                        OutputSettings().prettyPrint(pretty: false)) ?? ""
                // Remove the two last line break added after the last paragraph.
                if text.hasSuffix("\n\n") {
                    _ = text.removeLast()
                    _ = text.removeLast()
                }
                
                // Remove all whitespaces and newlines
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                
                asRawText = (try? Entities.unescape(text)) ?? text

                if asMarkdown.hasPrefix("\n") {
                    _ = asMarkdown.removeFirst()
                }

            } catch {
                asRawText = htmlValue
            }
        }

        do {
            let options = AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace)
            asSafeMarkdownAttributedString = try AttributedString(
                markdown: asMarkdown.trimmingCharacters(in: .whitespacesAndNewlines), options: options)
        } catch {
            asSafeMarkdownAttributedString = AttributedString(
                stringLiteral: htmlValue)
        }
    }

    init(stringValue: String, parseMarkdown: Bool = false) {
        htmlValue = stringValue
        asMarkdown = stringValue
        asRawText = stringValue
        statusesURLs = []

        if parseMarkdown {
            do {
                let options = AttributedString.MarkdownParsingOptions(
                    allowsExtendedAttributes: true,
                    interpretedSyntax: .inlineOnlyPreservingWhitespace)
                asSafeMarkdownAttributedString = try AttributedString(
                    markdown: asMarkdown, options: options)
            } catch {
                asSafeMarkdownAttributedString = AttributedString(
                    stringLiteral: htmlValue)
            }
        } else {
            asSafeMarkdownAttributedString = AttributedString(
                stringLiteral: htmlValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(htmlValue, forKey: .htmlValue)
        try container.encode(asMarkdown, forKey: .asMarkdown)
        try container.encode(asRawText, forKey: .asRawText)
        try container.encode(statusesURLs, forKey: .statusesURLs)
        try container.encode(links, forKey: .links)
    }

    private mutating func handleNode(
        node: SwiftSoup.Node,
        indent: Int? = 0,
        skipParagraph: Bool = false,
        listCounters: inout [Int]
    ) {
        do {
            if let className = try? node.attr("class") {
                if className == "invisible" {
                    // don't display
                    return
                }

                if className == "ellipsis" {
                    // descend into this one now and
                    // append the ellipsis
                    for nn in node.getChildNodes() {
                        handleNode(
                            node: nn, indent: indent,
                            listCounters: &listCounters)
                    }
                    asMarkdown += "…"
                    return
                }
            }

            if node.nodeName() == "p" {
                if asMarkdown.count > 0 && !skipParagraph {
                    asMarkdown += "\n\n"
                }
            } else if node.nodeName() == "br" {
                if asMarkdown.count > 0 {  // ignore first opening <br>
                    asMarkdown += "\n"
                }
                if (indent ?? 0) > 0 {
                    asMarkdown += "\n"
                }
            } else if node.nodeName() == "a" {
                let href = try node.attr("href")
                if href != "" {
                    if let url = URL(string: href) {
                        if Int(url.lastPathComponent) != nil {
                            statusesURLs.append(url)
                        } else if url.host() == "www.threads.net"
                            || url.host() == "threads.net",
                            url.pathComponents.count == 4,
                            url.pathComponents[2] == "post"
                        {
                            statusesURLs.append(url)
                        }
                    }
                }
                asMarkdown += "["
                let start = asMarkdown.endIndex
                // descend into this node now so we can wrap the
                // inner part of the link in the right markup
                for nn in node.getChildNodes() {
                    handleNode(node: nn, listCounters: &listCounters)
                }
                let finish = asMarkdown.endIndex

                var linkRef = href

                // Try creating a URL from the string. If it fails, try URL encoding
                //   the string first.
                var url = URL(string: href)
                if url == nil {
                    url = URL(string: href, encodePath: true)
                }
                if let linkUrl = url {
                    linkRef = linkUrl.absoluteString
                    let displayString = asMarkdown[start..<finish]
                    links.append(
                        Link(linkUrl, displayString: String(displayString)))
                }

                asMarkdown += "]("
                asMarkdown += linkRef
                asMarkdown += ")"

                return
            } else if node.nodeName() == "#text" {
                var txt = node.description

                txt = (try? Entities.unescape(txt)) ?? txt

                if let underscore_regex, let main_regex {
                    //  This is the markdown escaper
                    txt = main_regex.stringByReplacingMatches(
                        in: txt, options: [],
                        range: NSRange(location: 0, length: txt.count),
                        withTemplate: "\\\\$1")
                    txt = underscore_regex.stringByReplacingMatches(
                        in: txt, options: [],
                        range: NSRange(location: 0, length: txt.count),
                        withTemplate: "\\\\$1")
                }
                // Strip newlines and line separators - they should be being sent as <br>s
                asMarkdown += txt.replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(
                        of: "\u{2028}", with: "")
            } else if node.nodeName() == "blockquote" {
                asMarkdown += "\n\n`"
                for nn in node.getChildNodes() {
                    handleNode(
                        node: nn, indent: indent, listCounters: &listCounters)
                }
                asMarkdown += "`"
                return
            } else if node.nodeName() == "strong" || node.nodeName() == "b" {
                asMarkdown += "**"
                for nn in node.getChildNodes() {
                    handleNode(
                        node: nn, indent: indent, listCounters: &listCounters)
                }
                asMarkdown += "**"
                return
            } else if node.nodeName() == "em" || node.nodeName() == "i" {
                asMarkdown += "_"
                for nn in node.getChildNodes() {
                    handleNode(
                        node: nn, indent: indent, listCounters: &listCounters)
                }
                asMarkdown += "_"
                return
            } else if node.nodeName() == "ul" || node.nodeName() == "ol" {

                if skipParagraph {
                    asMarkdown += "\n"
                } else {
                    asMarkdown += "\n\n"
                }

                var listCounters = listCounters

                if node.nodeName() == "ol" {
                    listCounters.append(1)  // Start numbering for a new ordered list
                }

                for nn in node.getChildNodes() {
                    handleNode(
                        node: nn, indent: (indent ?? 0) + 1,
                        listCounters: &listCounters)
                }

                if node.nodeName() == "ol" {
                    listCounters.removeLast()
                }

                return
            } else if node.nodeName() == "li" {
                asMarkdown += "   "
                if let indent, indent > 1 {
                    for _ in 0..<indent {
                        asMarkdown += "   "
                    }
                    asMarkdown += "- "
                }

                if listCounters.isEmpty {
                    asMarkdown += "• "
                } else {
                    let currentIndex = listCounters.count - 1
                    asMarkdown += "\(listCounters[currentIndex]). "
                    listCounters[currentIndex] += 1
                }

                for nn in node.getChildNodes() {
                    handleNode(
                        node: nn, indent: indent, skipParagraph: true,
                        listCounters: &listCounters)
                }
                asMarkdown += "\n"
                return
            }

            for n in node.getChildNodes() {
                handleNode(node: n, indent: indent, listCounters: &listCounters)
            }
        } catch {}
    }

    struct Link: Codable, Hashable, Identifiable {
        var id: Int { hashValue }
        let url: URL
        let displayString: String
        let type: LinkType
        let title: String
        let neodbItem: (any ItemProtocol)?

        init(_ url: URL, displayString: String) {
            self.url = url
            self.displayString = displayString
            
            // Try to parse NeoDB item first
            self.neodbItem = NeoDBURL.parseItemURL(url, title: displayString)
            
            switch displayString.first {
            case "@":
                type = .mention
                title = displayString
            case "#":
                type = .hashtag
                title = String(displayString.dropFirst())
            default:
                type = .url
                var hostNameUrl = url.host ?? url.absoluteString
                if hostNameUrl.hasPrefix("www.") {
                    hostNameUrl = String(hostNameUrl.dropFirst(4))
                }
                title = hostNameUrl
            }
        }
        
        // MARK: - Codable
        private enum CodingKeys: String, CodingKey {
            case url, displayString, type, title
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            url = try container.decode(URL.self, forKey: .url)
            displayString = try container.decode(String.self, forKey: .displayString)
            type = try container.decode(LinkType.self, forKey: .type)
            title = try container.decode(String.self, forKey: .title)
            neodbItem = NeoDBURL.parseItemURL(url, title: displayString)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(url, forKey: .url)
            try container.encode(displayString, forKey: .displayString)
            try container.encode(type, forKey: .type)
            try container.encode(title, forKey: .title)
        }
        
        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
            hasher.combine(displayString)
            hasher.combine(type)
            hasher.combine(title)
        }
        
        static func == (lhs: Link, rhs: Link) -> Bool {
            lhs.url == rhs.url &&
            lhs.displayString == rhs.displayString &&
            lhs.type == rhs.type &&
            lhs.title == rhs.title
        }

        enum LinkType: String, Codable {
            case url
            case mention
            case hashtag
        }
    }
}

extension URL {
    // It's common to use non-ASCII characters in URLs even though they're technically
    //   invalid characters. Every modern browser handles this by silently encoding
    //   the invalid characters on the user's behalf. However, trying to create a URL
    //   object with un-encoded characters will result in nil so we need to encode the
    //   invalid characters before creating the URL object. The unencoded version
    //   should still be shown in the displayed status.
    init?(string: String, encodePath: Bool) {
        var encodedUrlString = ""
        if encodePath,
            string.starts(with: "http://") || string.starts(with: "https://"),
            var startIndex = string.firstIndex(of: "/")
        {
            startIndex = string.index(startIndex, offsetBy: 1)

            // We don't want to encode the host portion of the URL
            if var startIndex = string[startIndex...].firstIndex(of: "/") {
                encodedUrlString = String(string[...startIndex])
                while let endIndex = string[string.index(after: startIndex)...]
                    .firstIndex(of: "/")
                {
                    let componentStartIndex = string.index(after: startIndex)
                    encodedUrlString =
                        encodedUrlString
                        + (string[componentStartIndex...endIndex]
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed) ?? "")
                    startIndex = endIndex
                }

                // The last part of the path may have a query string appended to it
                let componentStartIndex = string.index(after: startIndex)
                if let queryStartIndex = string[componentStartIndex...]
                    .firstIndex(of: "?")
                {
                    encodedUrlString =
                        encodedUrlString
                        + (string[componentStartIndex..<queryStartIndex]
                            .addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed) ?? "")
                    encodedUrlString =
                        encodedUrlString
                        + (string[queryStartIndex...].addingPercentEncoding(
                            withAllowedCharacters: .urlQueryAllowed) ?? "")
                } else {
                    encodedUrlString =
                        encodedUrlString
                        + (string[componentStartIndex...].addingPercentEncoding(
                            withAllowedCharacters: .urlPathAllowed) ?? "")
                }
            }
        }
        if encodedUrlString.isEmpty {
            encodedUrlString = string
        }
        self.init(string: encodedUrlString)
    }
}
