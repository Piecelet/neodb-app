//
//  InstanceEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

enum InstanceEndpoint {
    case instance(instance: String? = nil)
    case peers
}

extension InstanceEndpoint: NetworkEndpoint {
    var host: HostType {
        switch self {
        case .instance(let instance):
            if let instance = instance {
                return .custom(instance)
            } else {
                return .currentInstance
            }
        case .peers:
            return .currentInstance
        }
    }

    var type: EndpointType {
        .apiV1
    }
    
    var path: String {
        switch self {
        case .instance: return "/instance"
        case .peers: return "/instance/peers"
        }
    }
}
