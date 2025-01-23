//
//  NeoDBAccountLoginEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

enum NeoDBAccountLoginEndpoint {
    case login
    case mastodon(referer: URL, cookie: String, csrfmiddlewaretoken: String, instance: String)
}

extension NeoDBAccountLoginEndpoint: NetworkEndpoint {
    var type: EndpointType {
        return .raw
    }

    var path: String {
        switch self {
        case .login:
            return "/account/login"
        case .mastodon:
            return "/account/mastodon/login"
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .mastodon(let referer, let cookie, _, _):
            return [
                "Origin": referer.host ?? "",
                "Referer": referer.absoluteString,
//                "Cookie": cookie,
//                "User-Agent": AppConfig.OAuth.userAgent,
            ]
        default:
            return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .mastodon(_, _, let csrfmiddlewaretoken, let instance):
            return [
                .init(name: "csrfmiddlewaretoken", value: csrfmiddlewaretoken),
                .init(name: "method", value: "mastodon"),
                .init(name: "domain", value: instance)
            ]
        default:
            return nil
        }
    }

    var responseType: ResponseType {
        return .html
    }
}


