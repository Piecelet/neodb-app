//
//  NetworkEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum ContentType {
    case json
    case urlEncoded

    var headerValue: String {
        switch self {
        case .json:
            return "application/json"
        case .urlEncoded:
            return "application/x-www-form-urlencoded"
        }
    }
}

enum HostType {
    case currentInstance
    case custom(String)
}

enum EndpointType {
    case oauth
    case api
    case apiV1
    case apiV2
    case raw
}

enum ResponseType {
    case json
    case html
}

protocol NetworkEndpoint {
    var type: EndpointType { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var bodyJson: Encodable? { get }
    var bodyUrlEncoded: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
}

extension NetworkEndpoint {
    var host: HostType {
        return .currentInstance
    }

    var type: EndpointType {
        return .api
    }

    var method: HTTPMethod {
        return .get
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }

    var bodyJson: Encodable? {
        return nil
    }

    var bodyUrlEncoded: [URLQueryItem]? {
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
