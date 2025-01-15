//
//  ShelfEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ShelfEndpoint {
    case get(type: ShelfType, category: ItemCategory? = nil, page: Int? = 1)
    case getItem(itemId: String)
    case markItem(itemId: String, mark: MarkInSchema)
    case deleteMark(itemId: String)
}

extension ShelfEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .get(let type, _, _):
            return "/me/shelf/\(type.rawValue)"
        case .getItem(let itemId):
            return "/me/shelf/item/\(itemId)"
        case .markItem(let itemId, _):
            return "/me/shelf/item/\(itemId)"
        case .deleteMark(let itemId):
            return "/me/shelf/item/\(itemId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get, .getItem:
            return .get
        case .markItem:
            return .post
        case .deleteMark:
            return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .get(_, let category, let page):
            var items: [URLQueryItem] = []
            
            if let category = category {
                items.append(.init(name: "category", value: category.rawValue))
            }
            
            if let page = page {
                items.append(.init(name: "page", value: String(page)))
            }
            
            return items.isEmpty ? nil : items
            
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .markItem(_, let mark):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return try? encoder.encode(mark)
        default:
            return nil
        }
    }
}
