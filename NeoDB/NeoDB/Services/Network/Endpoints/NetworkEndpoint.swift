//
//  NetworkEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum ContentType {
    case json
    case urlencoded

    var headerValue: String {
        switch self {
        case .json:
            return "application/json"
        case .urlencoded:
            return "application/x-www-form-urlencoded"
        }
    }
}

protocol NetworkEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var bodyContentType: ContentType? { get }
    var body: Data? { get }
    var headers: [String: String]? { get }
}

extension NetworkEndpoint {
    var method: HTTPMethod {
        return .get
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }

    var bodyContentType: ContentType? {
        return .json
    }

    var body: Data? {
        return nil
    }

    var headers: [String: String]? {
        return nil
    }

    func makePaginationParam(sinceId: String?, maxId: String?, mindId: String?)
        -> [URLQueryItem]?
    {
        if let sinceId {
            return [.init(name: "since_id", value: sinceId)]
        } else if let maxId {
            return [.init(name: "max_id", value: maxId)]
        } else if let mindId {
            return [.init(name: "min_id", value: mindId)]
        }
        return nil
    }
}
