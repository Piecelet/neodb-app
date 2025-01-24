//
//  ShelfType.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ShelfType: String, Codable, CaseIterable {
    case wishlist
    case progress
    case complete
    case dropped

    var displayName: String {
        switch self {
        case .wishlist:
            return String(localized: "shelf_type_wishlist", table: "Item")
        case .progress:
            return String(localized: "shelf_type_progress", table: "Item")
        case .complete:
            return String(localized: "shelf_type_complete", table: "Item")
        case .dropped:
            return String(localized: "shelf_type_dropped", table: "Item")
        }
    }

    var displayActionState: String {
        switch self {
        case .wishlist:
            return String(localized: "shelf_type_action_wishlist", table: "Item")
        case .progress:
            return String(localized: "shelf_type_action_progress", table: "Item")
        case .complete:
            return String(localized: "shelf_type_action_complete", table: "Item")
        case .dropped:
            return String(localized: "shelf_type_action_dropped", table: "Item")
        }
    }

    var iconName: String {
        switch self {
        case .wishlist:
            return "heart"
        case .progress:
            return "book"
        case .complete:
            return "checkmark.circle"
        case .dropped:
            return "xmark.circle"
        }
    }

    var symbolImage: Symbol {
        switch self {
        case .wishlist: return .sfSymbol(.heart)
        case .progress: return .sfSymbol(.book)
        case .complete: return .sfSymbol(.checkmarkCircle)
        case .dropped: return .sfSymbol(.xmarkCircle)
        }
    }

    var symbolImageFill: Symbol {
        switch self {
        case .wishlist: return .sfSymbol(.heartFill)
        case .progress: return .sfSymbol(.bookFill)
        case .complete: return .sfSymbol(.checkmarkCircleFill)
        case .dropped: return .sfSymbol(.xmarkCircleFill)
        }
    }
}
