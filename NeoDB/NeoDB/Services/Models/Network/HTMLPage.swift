//
//  HTMLPage.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation
import SwiftSoup

private enum CodingKeys: CodingKey {
    case htmlValue, asRawText, csrfmiddlewaretoken
}

struct HTMLPage: Codable, Equatable, Hashable, @unchecked Sendable {
    var htmlValue: String = ""
    var asRawText: String = ""
    private(set) var csrfmiddlewaretoken: String?
    
    init(from decoder: Decoder) {
        var alreadyDecoded = false
        do {
            let container = try decoder.singleValueContainer()
            htmlValue = try container.decode(String.self)
        } catch {
            do {
                alreadyDecoded = true
                let container = try decoder.container(keyedBy: CodingKeys.self)
                htmlValue = try container.decode(String.self, forKey: .htmlValue)
                asRawText = try container.decode(String.self, forKey: .asRawText)
                csrfmiddlewaretoken = try container.decode(String?.self, forKey: .csrfmiddlewaretoken)
            } catch {
                htmlValue = ""
            }
        }
        
        if !alreadyDecoded {
            do {
                let document: Document = try SwiftSoup.parse(htmlValue)
                
                // Extract CSRF token
                if let csrfInput = try document.select("input[name=csrfmiddlewaretoken]").first() {
                    csrfmiddlewaretoken = try csrfInput.attr("value")
                }
                
                // Clean and get raw text
                document.outputSettings(OutputSettings().prettyPrint(pretty: false))
                let html = try document.html()
                var text = try SwiftSoup.clean(html, "", Whitelist.none(), 
                    OutputSettings().prettyPrint(pretty: false)) ?? ""
                
                // Remove all whitespaces and newlines
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                
                asRawText = (try? Entities.unescape(text)) ?? text
                
            } catch {
                asRawText = htmlValue
            }
        }
    }
    
    init(stringValue: String) {
        htmlValue = stringValue
        asRawText = stringValue
        
        do {
            let document: Document = try SwiftSoup.parse(stringValue)
            if let csrfInput = try? document.select("input[name=csrfmiddlewaretoken]").first() {
                csrfmiddlewaretoken = try? csrfInput.attr("value")
            }
        } catch {
            // Silently fail if parsing fails
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(htmlValue, forKey: .htmlValue)
        try container.encode(asRawText, forKey: .asRawText)
        try container.encode(csrfmiddlewaretoken, forKey: .csrfmiddlewaretoken)
    }
}

