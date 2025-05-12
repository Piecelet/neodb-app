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
    let externalAccounts: [ExternalAccount]
    let displayName: String
    let avatar: URL
    let username: String
    let roles: [UserRoles]

    var id: URL {
        return url
    }
}

struct ExternalAccount: Codable, Hashable, Identifiable {
    let platform, handle: String
    let url: String?
    
    var id: String {
        return url ?? "\(platform)-\(handle)"
    }
}

enum UserRoles: String, Codable {
    case admin
    case staff
}


extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.url == rhs.url
    }
    
    static func placeholder() -> User {
        return User(
            url: URL(string: "https://placehold.co/100x100")!,
            externalAcct: nil,
            externalAccounts: [],
            displayName: String(localized: "account_displayname", table: "Settings", comment: "A placeholder of the display name of an account."),
            avatar: URL(string: "https://placehold.co/100x100")!,
            username: "@username",
            roles: [])
    }
}

struct UserUnauthorized: Codable {
    let detail: String

    enum CodingKeys: String, CodingKey {
        case detail
    }
}
