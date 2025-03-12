//
//  FollowRequestsEndpoint.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 3/12/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum FollowRequestsEndpoint {
    case list
    case accept(id: String)
    case reject(id: String)
}

extension FollowRequestsEndpoint: NetworkEndpoint {
    var type: EndpointType {
        return .apiV1
    }

    var path: String {
        switch self {
        case .list: return "follow_requests"
        case .accept(let id): return "follow_requests/\(id)/authorize"
        case .reject(let id): return "follow_requests/\(id)/reject"
        }
    }
}
