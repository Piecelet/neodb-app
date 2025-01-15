//
//  ShelfEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ShelfEndpoint {
    case get(type: ShelfType, category: ItemCategory?, page: Int? = 1)
    case getItem(itemId: String)
    case markItem(itemId: String, mark: MarkInSchema)
    case deleteMark(itemId: String)
}

extension ShelfEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .get(let type, _, _):
            return "/shelf/\(type.rawValue)"
        case .getItem(let itemId):
            return "/item/\(itemId)"
        case .markItem(let itemId, _):
            return "/item/\(itemId)"
        case .deleteMark(let itemId):
            return "/item/\(itemId)"
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
            return [
                .init(name: "category", value: category?.rawValue),
                .init(name: "page", value: page.map(String.init)),
            ]
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
