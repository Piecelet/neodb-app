//
//  ShelfEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ShelfEndpoint {
    case get(type: ShelfType, category: ItemCategory.shelfAvailable? = nil, page: Int? = 1)
}

extension ShelfEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .get(let type, _, _):
            return "/me/shelf/\(type.rawValue)"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .get(_, let category, let page):
            var items: [URLQueryItem] = []
            
            if let category = category, category != .allItems {
                items.append(.init(name: "category", value: category.rawValue))
            }
            
            if let page = page {
                items.append(.init(name: "page", value: String(page)))
            }
            
            return items.isEmpty ? nil : items
        }
    }
}
