//
//  User.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Foundation

struct User: Codable, Identifiable {
    let url: URL
    let externalAcct: String?
    let displayName: String
    let avatar: URL
    let username: String

    var id: URL {
        return url
    }
}

extension User: Equatable {
    static func placeholder() -> User {
        return User(
            url: URL(string: "https://placehold.co/100x100")!,
            externalAcct: nil,
            displayName: "Name",
            avatar: URL(string: "https://placehold.co/100x100")!,
            username: "@username")
    }
}

struct UserUnauthorized: Codable {
    let detail: String

    enum CodingKeys: String, CodingKey {
        case detail
    }
}
