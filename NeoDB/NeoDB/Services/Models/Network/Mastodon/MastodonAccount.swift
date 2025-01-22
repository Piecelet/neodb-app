//
//  MastodonAccount.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

final class MastodonAccount: Codable, Identifiable, Hashable, Sendable,
    Equatable
{
    static func == (lhs: MastodonAccount, rhs: MastodonAccount) -> Bool {
        lhs.id == rhs.id && lhs.username == rhs.username
            && lhs.note.asRawText == rhs.note.asRawText
            && lhs.statusesCount == rhs.statusesCount
            && lhs.followersCount == rhs.followersCount
            && lhs.followingCount == rhs.followingCount && lhs.acct == rhs.acct
            && lhs.displayName == rhs.displayName && lhs.fields == rhs.fields
            && lhs.lastStatusAt == rhs.lastStatusAt
            && lhs.discoverable == rhs.discoverable
            && lhs.bot == rhs.bot && lhs.locked == rhs.locked
            && lhs.avatar == rhs.avatar
            && lhs.header == rhs.header
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    struct Field: Codable, Equatable, Identifiable, Sendable {
        var id: String {
            value.asRawText + name
        }

        let name: String
        let value: HTMLString
        let verifiedAt: String?
    }

    struct Source: Codable, Equatable, Sendable {
        let privacy: Visibility
        let sensitive: Bool
        let language: String?
        let note: String
        let fields: [Field]
    }

    let id: String
    let username: String
    let displayName: String?
    let cachedDisplayName: HTMLString
    let avatar: URL
    let header: URL
    let acct: String
    let note: HTMLString
    let createdAt: ServerDate
    let followersCount: Int?
    let followingCount: Int?
    let statusesCount: Int?
    let lastStatusAt: String?
    let fields: [Field]
    let locked: Bool
    let emojis: [MastodonEmoji]
    let url: URL?
    let source: Source?
    let bot: Bool
    let discoverable: Bool?
    let moved: MastodonAccount?

    var haveAvatar: Bool {
        avatar.lastPathComponent != "missing.png"
    }

    var haveHeader: Bool {
        header.lastPathComponent != "missing.png"
    }

    var fullAccountName: String {
        "\(acct)@\(url?.host() ?? "")"
    }

    init(
        id: String, username: String, displayName: String?, avatar: URL,
        header: URL, acct: String,
        note: HTMLString, createdAt: ServerDate, followersCount: Int,
        followingCount: Int,
        statusesCount: Int, lastStatusAt: String? = nil,
        fields: [MastodonAccount.Field], locked: Bool,
        emojis: [MastodonEmoji], url: URL? = nil, source: Source? = nil,
        bot: Bool,
        discoverable: Bool? = nil, moved: MastodonAccount? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatar = avatar
        self.header = header
        self.acct = acct
        self.note = note
        self.createdAt = createdAt
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.statusesCount = statusesCount
        self.lastStatusAt = lastStatusAt
        self.fields = fields
        self.locked = locked
        self.emojis = emojis
        self.url = url
        self.source = source
        self.bot = bot
        self.discoverable = discoverable
        self.moved = moved

        if let displayName, !displayName.isEmpty {
            cachedDisplayName = .init(stringValue: displayName)
        } else {
            cachedDisplayName = .init(stringValue: "@\(username)")
        }
    }

    enum CodingKeys: CodingKey {
        case id
        case username
        case displayName
        case avatar
        case header
        case acct
        case note
        case createdAt
        case followersCount
        case followingCount
        case statusesCount
        case lastStatusAt
        case fields
        case locked
        case emojis
        case url
        case source
        case bot
        case discoverable
        case moved
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(
            String.self, forKey: .displayName)
        avatar = try container.decode(URL.self, forKey: .avatar)
        header = try container.decode(URL.self, forKey: .header)
        acct = try container.decode(String.self, forKey: .acct)
        note = try container.decode(HTMLString.self, forKey: .note)
        createdAt = try container.decode(ServerDate.self, forKey: .createdAt)
        followersCount = try container.decodeIfPresent(
            Int.self, forKey: .followersCount)
        followingCount = try container.decodeIfPresent(
            Int.self, forKey: .followingCount)
        statusesCount = try container.decodeIfPresent(
            Int.self, forKey: .statusesCount)
        lastStatusAt = try container.decodeIfPresent(
            String.self, forKey: .lastStatusAt)
        fields = try container.decode(
            [MastodonAccount.Field].self, forKey: .fields)
        locked = try container.decode(Bool.self, forKey: .locked)
        emojis = try container.decode([MastodonEmoji].self, forKey: .emojis)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        source = try container.decodeIfPresent(
            MastodonAccount.Source.self, forKey: .source)
        bot = try container.decode(Bool.self, forKey: .bot)
        discoverable = try container.decodeIfPresent(
            Bool.self, forKey: .discoverable)
        moved = try container.decodeIfPresent(
            MastodonAccount.self, forKey: .moved)

        if let displayName, !displayName.isEmpty {
            cachedDisplayName = .init(stringValue: displayName)
        } else {
            cachedDisplayName = .init(stringValue: "@\(username)")
        }
    }

    static func placeholder() -> MastodonAccount {
        .init(
            id: UUID().uuidString,
            username: "Username",
            displayName: "John Mastodon",
            avatar: URL(
                string:
                    "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png"
            )!,
            header: URL(
                string:
                    "https://files.mastodon.social/media_attachments/files/003/134/405/original/04060b07ddf7bb0b.png"
            )!,
            acct: "johnm@example.com",
            note: .init(stringValue: "Some content"),
            createdAt: ServerDate(),
            followersCount: 10,
            followingCount: 10,
            statusesCount: 10,
            lastStatusAt: nil,
            fields: [],
            locked: false,
            emojis: [],
            url: nil,
            source: nil,
            bot: false,
            discoverable: true)
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

struct MastodonFamiliarAccounts: Decodable {
    let id: String
    let accounts: [MastodonAccount]
}

extension MastodonFamiliarAccounts: Sendable {}
