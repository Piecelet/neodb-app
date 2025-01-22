//
//  TrendsEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import Foundation

enum TrendsEndpoint {
    case tags
    case statuses(offset: Int?)
    case links(offset: Int?)
}

extension TrendsEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .tags:
            return "/v1/trends/tags"
        case .statuses:
            return "/v1/trends/statuses"
        case .links:
            return "/v1/trends/links"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .statuses(offset), let .links(offset):
            if let offset {
                return [.init(name: "offset", value: String(offset))]
            }
            return nil
        default:
            return nil
        }
    }
}
