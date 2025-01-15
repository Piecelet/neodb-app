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
            return "Want to Read"
        case .progress:
            return "Reading"
        case .complete:
            return "Completed"
        case .dropped:
            return "Dropped"
        }
    }

    var systemImage: String {
        switch self {
        case .wishlist:
            return "star"
        case .progress:
            return "book"
        case .complete:
            return "checkmark.circle"
        case .dropped:
            return "xmark.circle"
        }
    }
}
