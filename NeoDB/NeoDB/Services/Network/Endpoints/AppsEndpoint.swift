//
//  AppEndpoints.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

enum AppsEndpoint {
    case create
}

extension AppsEndpoint: NetworkEndpoint {
    var type: EndpointType {
        return .apiV1
    }

    var path: String {
        switch self {
        case .create:
            return "/apps"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        }
    }

 var bodyUrlEncoded: [URLQueryItem]? {
   switch self {
   case .create:
     return [
       .init(name: "client_name", value: AppConfig.PublicInfo.name),
       .init(name: "redirect_uris", value: AppConfig.OAuth.redirectUri),
       .init(name: "scopes", value: AppConfig.OAuth.scopes),
       .init(name: "website", value: AppConfig.PublicInfo.website),
     ]
   }
 }
  
}
