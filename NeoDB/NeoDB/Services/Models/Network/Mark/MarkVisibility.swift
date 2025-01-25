//
//  MarkVisibility.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation

enum MarkVisibility: Int, Codable, CaseIterable {
    case pub = 0
    case unlisted = 1
    case priv = 2

    var displayText: String {
        switch self {
        case .pub: return "Public"
        case .unlisted: return "Unlisted"
        case .priv: return "Private"
        }
    }

    var descriptionText: String {
        switch self {
        case .pub: return "Everyone can see it."
        case .unlisted: return "Not shown on timeline, but can be seen by anyone with the link."
        case .priv: return "Only you can see it."
        }
    }

    var symbolImage: Symbol {
        switch self {
        case .pub: return .sfSymbol(.globe)
        case .unlisted: return .sfSymbol(.moonZzz)
        case .priv: return .sfSymbol(.lock)
        }
    }

    var symbolImageFill: Symbol {
        switch self {
        case .pub: return .sfSymbol(.globe)
        case .unlisted: return .sfSymbol(.moonZzzFill)
        case .priv: return .sfSymbol(.lockFill)
        }
    }
}
