//
//  InstanceEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

enum InstanceEndpoint {
    case instance
    case peers
}

extension InstanceEndpoint: NetworkEndpoint {
    var type: EndpointType {
        .apiV2
    }
    
    var path: String {
        switch self {
        case .instance: return "/instance"
        case .peers: return "/instance/peers"
        }
    }
}
