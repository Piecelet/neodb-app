//
//  StreamingEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import Foundation

enum StreamingEndpoint: NetworkEndpoint {
    case streaming
    
    var path: String {
        switch self {
        case .streaming:
            return "/v1/streaming"
        }
    }
} 
