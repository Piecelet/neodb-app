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
            return "Wishlist"
        case .progress:
            return "Progress"
        case .complete:
            return "Complete"
        case .dropped:
            return "Dropped"
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
}
