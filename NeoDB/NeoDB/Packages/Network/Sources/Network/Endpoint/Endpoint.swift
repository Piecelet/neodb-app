//
//  Endpoint.swift
//  Network
//
//  Created by citron on 12/24/24.
//

import Foundation

public protocol Endpoint {
    func path() -> String
    func queryItems() -> [URLQueryItem]?
}

