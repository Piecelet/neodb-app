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
        case .pub:
            return String(localized: "mark_visibility_public_label", table: "Item", comment: "Mark Visibility - Label for public visibility option")
        case .unlisted:
            return String(localized: "mark_visibility_unlisted_label", table: "Item", comment: "Mark Visibility - Label for unlisted visibility option")
        case .priv:
            return String(localized: "mark_visibility_private_label", table: "Item", comment: "Mark Visibility - Label for private visibility option")
        }
    }

    var descriptionText: String {
        switch self {
        case .pub:
            return String(localized: "mark_visibility_public_description", table: "Item", comment: "Mark Visibility - Description for public visibility option")
        case .unlisted:
            return String(localized: "mark_visibility_unlisted_description", table: "Item", comment: "Mark Visibility - Description for unlisted visibility option")
        case .priv:
            return String(localized: "mark_visibility_private_description", table: "Item", comment: "Mark Visibility - Description for private visibility option")
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
