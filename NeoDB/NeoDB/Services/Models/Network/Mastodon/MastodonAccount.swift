//
//  MastodonAccount.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

struct MastodonAccount: Codable, Identifiable, Equatable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    struct Field: Codable, Equatable, Identifiable {
        var id: String {
            value + name
        }

        let name: String
        let value: HTMLString
        let verifiedAt: String?
    }
    let id: String
    let username: String
    let displayName: String
    let avatar: URL
    let header: URL
    let acct: String
    let note: HTMLString
    let createdAt: ServerDate
    let followersCount: Int
    let followingCount: Int
    let statusesCount: Int
    let lastStatusAt: String?
    let fields: [Field]
    let locked: Bool
    let emojis: [MastodonEmoji]

    static func placeholder() -> MastodonAccount {
        .init(
            id: UUID().uuidString,
            username: "Username",
            displayName: "Display Name",
            avatar: URL(
                string:
                    "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png"
            )!,
            header: URL(
                string:
                    "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png"
            )!,
            acct: "account@account.com",
            note: "Some content",
            createdAt: "2022-12-16T10:20:54.000Z",
            followersCount: 10,
            followingCount: 10,
            statusesCount: 10,
            lastStatusAt: nil,
            fields: [],
            locked: false,
            emojis: [])
    }

    static func placeholders() -> [MastodonAccount] {
        [
            .placeholder(), .placeholder(), .placeholder(), .placeholder(),
            .placeholder(),
            .placeholder(), .placeholder(), .placeholder(), .placeholder(),
            .placeholder(),
        ]
    }
}

struct MastodonFamilliarAccounts: Codable {
    let id: String
    let accounts: [MastodonAccount]
}
