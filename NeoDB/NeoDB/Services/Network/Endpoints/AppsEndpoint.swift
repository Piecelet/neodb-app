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

  var queryItems: [URLQueryItem]? {
    switch self {
    case .create:
      return [
        .init(name: "client_name", value: "NeoDB iOS App"),
        .init(name: "redirect_uris", value: "neodb://oauth/callback"),
        .init(name: "website", value: "https://github.com/lcandy2/neodb-app"),
      ]
    }
  }
}
