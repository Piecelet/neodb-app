//
//  OauthToken.swift
//  NeoDB
//
//  Created by citron on 1/11/25.
//

import Foundation

struct OauthToken: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}
