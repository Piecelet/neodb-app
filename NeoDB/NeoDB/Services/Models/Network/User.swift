//
//  User.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Foundation

struct User: Codable {
    let url: URL
    let externalAcct: String?
    let displayName: String
    let avatar: URL
    let username: String
} 

struct UserUnauthorized: Codable {
    let detail: String

    enum CodingKeys: String, CodingKey {
        case detail
    }
}
