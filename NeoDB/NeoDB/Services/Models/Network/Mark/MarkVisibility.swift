//
//  MarkVisibility.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation

enum MarkVisibility: Int, Codable, CaseIterable {
    case pub = 0
    case followersOnly = 1
    case priv = 2

    var displayText: String {
        switch self {
        case .pub:
            return String(localized: "mark_visibility_public_label", table: "Item", comment: "Mark Visibility - Label for public visibility option")
        case .followersOnly:
            return String(localized: "mark_visibility_followers_only_label", table: "Item", comment: "Mark Visibility - Label for unlisted visibility option")
        case .priv:
            return String(localized: "mark_visibility_private_label", table: "Item", comment: "Mark Visibility - Label for private visibility option")
        }
    }

    var descriptionText: String {
        switch self {
        case .pub:
            return String(localized: "mark_visibility_public_description", table: "Item", comment: "Mark Visibility - Description for public visibility option")
        case .followersOnly:
            return String(localized: "mark_visibility_followers_only_description", table: "Item", comment: "Mark Visibility - Description for unlisted visibility option")
        case .priv:
            return String(localized: "mark_visibility_private_description", table: "Item", comment: "Mark Visibility - Description for private visibility option")
        }
    }

    var symbolImage: Symbol {
        switch self {
        case .pub: return .sfSymbol(.globe)
        case .followersOnly: return .sfSymbol(.person2)
        case .priv: return .sfSymbol(.lock)
        }
    }

    var symbolImageFill: Symbol {
        switch self {
        case .pub: return .sfSymbol(.globe)
        case .followersOnly: return .sfSymbol(.person2Fill)
        case .priv: return .sfSymbol(.lockFill)
        }
    }
}
