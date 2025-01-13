//
//  AppEndpoints.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum CreateAppEndpoints {
    case create(redirectUri: String)
}

extension CreateAppEndpoints: NetworkEndpoint {
        var path: String {
        switch self {
        case .create:
            return "/v1/apps"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        }
    }
    
    var body: Data? {
        switch self {
        case .create(let redirectUri):
            let parameters: [String: String] = [
                "client_name": "NeoDB iOS App",
                "redirect_uris": redirectUri,
                "website": "https://github.com/citron/neodb-app"
            ]
            return try? JSONSerialization.data(withJSONObject: parameters)
        }
    }
    
    var bodyContentType: ContentType? {
        switch self {
        case .create:
            return .json
        }
    }
}
