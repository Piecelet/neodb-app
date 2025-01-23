//
//  TimelinesEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum TimelinesEndpoint {
    case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool, limit: Int?)
    case home(sinceId: String?, maxId: String?, minId: String?, limit: Int?)
    case list(listId: String, sinceId: String?, maxId: String?, minId: String?)
    case hashtag(tag: String, additional: [String]?, maxId: String?, minId: String?)
    case link(url: URL, sinceId: String?, maxId: String?, minId: String?)
    case trending(maxId: String?)
}

extension TimelinesEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .pub:
            return "/v1/timelines/public"
        case .home:
            return "/v1/timelines/home"
        case .list(let listId, _, _, _):
            return "/v1/timelines/list/\(listId)"
        case .hashtag(let tag, _, _, _):
            return "/v1/timelines/tag/\(tag)"
        case .link:
            return "/v1/timelines/link"
        case .trending:
            return "/v1/trends/statuses"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
    case let .pub(sinceId, maxId, minId, local, limit):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      params.append(.init(name: "local", value: local ? "true" : "false"))
      if let limit {
        params.append(.init(name: "limit", value: String(limit)))
      }
      return params
    case let .home(sinceId, maxId, mindId, limit):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId) ?? []
      if let limit {
        params.append(.init(name: "limit", value: String(limit)))
      }
      return params
    case let .list(_, sinceId, maxId, mindId):
      return makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: mindId)
    case let .hashtag(_, additional, maxId, minId):
      var params = makePaginationParam(sinceId: nil, maxId: maxId, mindId: minId) ?? []
      params.append(
        contentsOf: (additional ?? [])
          .map { URLQueryItem(name: "any[]", value: $0) })
      return params
    case let .link(url, sinceId, maxId, minId):
      var params = makePaginationParam(sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
      params.append(.init(name: "url", value: url.absoluteString))
      return params
        case .trending(let maxId):
            if let maxId {
                return [.init(name: "max_id", value: maxId)]
            }
            return nil
        }
    }
}
