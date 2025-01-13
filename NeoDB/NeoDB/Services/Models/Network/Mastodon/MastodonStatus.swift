//
//  MastodonStatus.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

struct Application: Codable, Identifiable {
    var id: String {
        name
    }
    let name: String
    let website: URL?
}

enum Visibility: String, Codable, CaseIterable {
    case pub = "public"
    case unlisted
    case priv = "private"
    case direct
}

protocol AnyMastodonStatus {
    var viewId: String { get }
    var id: String { get }
    var content: HTMLString { get }
    var account: MastodonAccount { get }
    var createdAt: ServerDate { get }
    var editedAt: ServerDate? { get }
    var mediaAttachments: [MastodonMediaAttachement] { get }
    var mentions: [MastodonMention] { get }
    var repliesCount: Int { get }
    var reblogsCount: Int { get }
    var favouritesCount: Int { get }
    var tags: [MastodonTag] { get }
    var card: MastodonCard? { get }
    var favourited: Bool? { get }
    var reblogged: Bool? { get }
    var pinned: Bool? { get }
    var emojis: [MastodonEmoji] { get }
    var url: URL? { get }
    var application: Application? { get }
    var inReplyToAccountId: String? { get }
    var visibility: Visibility { get }
    var poll: MastodonPoll? { get }
    var spoilerText: String { get }
}

struct MastodonStatus: AnyMastodonStatus, Codable, Identifiable {
    var viewId: String {
        id + createdAt + (editedAt ?? "")
    }

    let id: String
    let content: HTMLString
    let account: MastodonAccount
    let createdAt: ServerDate
    let editedAt: ServerDate?
    let reblog: MastodonReblogStatus?
    let mediaAttachments: [MastodonMediaAttachement]
    let mentions: [MastodonMention]
    let repliesCount: Int
    let reblogsCount: Int
    let favouritesCount: Int
    let tags: [MastodonTag]
    let card: MastodonCard?
    let favourited: Bool?
    let reblogged: Bool?
    let pinned: Bool?
    let emojis: [MastodonEmoji]
    let url: URL?
    let application: Application?
    let inReplyToAccountId: String?
    let visibility: Visibility
    let poll: MastodonPoll?
    let spoilerText: String

    static func placeholder() -> MastodonStatus {
        .init(
            id: UUID().uuidString,
            content: "Some post content\n Some more post content \n Some more",
            account: .placeholder(),
            createdAt: "2022-12-16T10:20:54.000Z",
            editedAt: nil,
            reblog: nil,
            mediaAttachments: [],
            mentions: [],
            repliesCount: 0,
            reblogsCount: 0,
            favouritesCount: 0,
            tags: [],
            card: nil,
            favourited: false,
            reblogged: false,
            pinned: false,
            emojis: [],
            url: nil,
            application: nil,
            inReplyToAccountId: nil,
            visibility: .pub,
            poll: nil,
            spoilerText: "")
    }

    static func placeholders() -> [MastodonStatus] {
        [
            .placeholder(), .placeholder(), .placeholder(), .placeholder(),
            .placeholder(),
        ]
    }
}

struct MastodonReblogStatus: AnyMastodonStatus, Codable, Identifiable {
    var viewId: String {
        id + createdAt + (editedAt ?? "")
    }

    let id: String
    let content: String
    let account: MastodonAccount
    let createdAt: String
    let editedAt: ServerDate?
    let mediaAttachments: [MastodonMediaAttachement]
    let mentions: [MastodonMention]
    let repliesCount: Int
    let reblogsCount: Int
    let favouritesCount: Int
    let tags: [MastodonTag]
    let card: MastodonCard?
    let favourited: Bool?
    let reblogged: Bool?
    let pinned: Bool?
    let emojis: [MastodonEmoji]
    let url: URL?
    var application: Application?
    let inReplyToAccountId: String?
    let visibility: Visibility
    let poll: MastodonPoll?
    let spoilerText: String
}
