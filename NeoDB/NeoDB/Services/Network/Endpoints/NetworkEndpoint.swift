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

enum EndpointType {
    case oauth
    case api
    case apiV1
    case apiV2
    case raw
}

protocol NetworkEndpoint {
    var type: EndpointType { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var bodyContentType: ContentType? { get }
    var body: Encodable? { get }
    var headers: [String: String]? { get }
}

extension NetworkEndpoint {
    var type: EndpointType {
        return .api
    }

    var method: HTTPMethod {
        return .get
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }

    var bodyContentType: ContentType? {
        return .json
    }

    var body: Encodable? {
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
