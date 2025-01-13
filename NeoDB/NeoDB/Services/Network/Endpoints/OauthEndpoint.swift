//
//  OauthEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum OauthEndpoint {
    case token(code: String, clientId: String, clientSecret: String, redirectUri: String)
}

extension OauthEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .token:
            return "/oauth/token"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .token:
            return .post
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .token(let code, let clientId, let clientSecret, let redirectUri):
            return [
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "client_secret", value: clientSecret),
                URLQueryItem(name: "redirect_uri", value: redirectUri),
            ]
        }
    }
}

