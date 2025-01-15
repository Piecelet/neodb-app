//
//  MarkEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum MarkEndpoint {
    case get(itemId: String)
    case mark(itemId: String, mark: MarkInSchema)
    case delete(itemId: String)
}

extension MarkEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .get(let itemId):
            return "/me/shelf/item/\(itemId)"
        case .mark(let itemId, _):
            return "/me/shelf/item/\(itemId)"
        case .delete(let itemId):
            return "/me/shelf/item/\(itemId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get:
            return .get
        case .mark:
            return .post
        case .delete:
            return .delete
        }
    }

    var body: Data? {
        switch self {
        case .mark(_, let mark):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return try? encoder.encode(mark)
        default:
            return nil
        }
    }
}
