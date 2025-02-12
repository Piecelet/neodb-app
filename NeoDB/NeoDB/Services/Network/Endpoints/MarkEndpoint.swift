//
//  MarkEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum MarkEndpoint {
    case get(itemUUID: String)
    case mark(itemUUID: String, mark: MarkInSchema)
    case delete(itemUUID: String)
}

extension MarkEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .get(let itemUUID):
            return "/me/shelf/item/\(itemUUID)"
        case .mark(let itemUUID, _):
            return "/me/shelf/item/\(itemUUID)"
        case .delete(let itemUUID):
            return "/me/shelf/item/\(itemUUID)"
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

    var bodyJson: Encodable? {
        switch self {
        case .mark(_, let mark):
            return mark
        default:
            return nil
        }
    }
}
