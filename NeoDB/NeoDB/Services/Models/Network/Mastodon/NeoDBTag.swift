//
//  NeoDBTag.swift
//  NeoDB
//
//  Created by citron on 1/21/25.
//

import Foundation

public struct NeoDBTag: Codable, Identifiable {

    public var id: String {
        href.absoluteString
    }

    public let href: URL
    public let name: String
    public let type: String
    public let image: URL?
}
