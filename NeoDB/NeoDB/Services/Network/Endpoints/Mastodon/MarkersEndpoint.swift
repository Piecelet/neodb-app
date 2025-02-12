//
//  MarkersEndpoint.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum MarkersEndpoint {
    case markers
    case markNotifications(lastReadId: String)
    case markHome(lastReadId: String)
}

extension MarkersEndpoint: NetworkEndpoint {
    var type: EndpointType {
        return .apiV1
    }

    var path: String {
        return "markers"
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .markers:
            [
                URLQueryItem(name: "timeline[]", value: "home"),
                URLQueryItem(name: "timeline[]", value: "notifications"),
            ]
        case let .markNotifications(lastReadId):
            [
                URLQueryItem(
                    name: "notifications[last_read_id]", value: lastReadId)
            ]
        case let .markHome(lastReadId):
            [URLQueryItem(name: "home[last_read_id]", value: lastReadId)]
        }
    }
}
