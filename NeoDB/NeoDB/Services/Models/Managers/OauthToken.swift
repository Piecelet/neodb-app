//
//  OauthToken.swift
//  NeoDB
//
//  Created by citron on 1/11/25.
//

import Foundation

struct OauthToken: Codable, Hashable, Sendable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Double

    init(
        accessToken: String, tokenType: String, scope: String, createdAt: Double
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scope = scope
        self.createdAt = createdAt
    }
}
