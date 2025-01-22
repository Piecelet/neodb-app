//
//  TimelinesEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum TimelinesEndpoint {
    case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool, limit: Int?)
    case home(sinceId: String?, maxId: String?, minId: String?)
    case trending(maxId: String?)
}

extension TimelinesEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .pub:
            return "/v1/timelines/public"
        case .home:
            return "/v1/timelines/home"
        case .trending:
            return "/v1/trends/statuses"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .pub(let sinceId, let maxId, let minId, let local, let limit):
            var params =
                makePaginationParam(
                    sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
            params.append(.init(name: "local", value: local ? "true" : "false"))
            if let limit = limit { params.append(.init(name: "limit", value: String(describing: limit))) }
            return params
        case .home(let sinceId, let maxId, let mindId):
            return makePaginationParam(
                sinceId: sinceId, maxId: maxId, mindId: mindId)
        case .trending(let maxId):
            if let maxId {
                return [.init(name: "max_id", value: maxId)]
            }
            return nil
        }
    }
}
