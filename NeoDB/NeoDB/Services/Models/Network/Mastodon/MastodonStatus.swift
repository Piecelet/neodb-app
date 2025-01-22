//
//  MastodonStatus.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//
//  Based on https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
//

import Foundation

struct Application: Codable, Identifiable {
    var id: String {
        name
    }
    let name: String
    let website: URL?
}

enum Visibility: String, Codable, CaseIterable, Hashable, Equatable, Sendable {
    case pub = "public"
    case unlisted
    case priv = "private"
    case direct
}

protocol AnyMastodonStatus {
    var id: String { get }
    var content: HTMLString { get }
    var account: MastodonAccount { get }
    var createdAt: ServerDate { get }
    var editedAt: ServerDate? { get }
    var mediaAttachments: [MastodonMediaAttachment] { get }
    var mentions: [MastodonMention] { get }
    var repliesCount: Int { get }
    var reblogsCount: Int { get }
    var favouritesCount: Int { get }
    var tags: [MastodonTag] { get }
    var card: MastodonCard? { get }
    var favourited: Bool? { get }
    var reblogged: Bool? { get }
    var pinned: Bool? { get }
    var bookmarked: Bool? { get }
    var emojis: [MastodonEmoji] { get }
    var url: String? { get }
    var application: Application? { get }
    var inReplyToId: String? { get }
    var inReplyToAccountId: String? { get }
    var visibility: Visibility { get }
    var poll: MastodonPoll? { get }
    var spoilerText: HTMLString { get }
    var filtered: [MastodonFiltered]? { get }
    var sensitive: Bool { get }
    var language: String? { get }
    var isHidden: Bool { get }

    // MARK: NeoDB Private
    //    var extNeodb: [NeoDBTag] {get}
    //    var relatedWith:
}

struct MastodonStatus: AnyMastodonStatus, Codable, Identifiable, Equatable,
    Hashable
{
    static func == (lhs: MastodonStatus, rhs: MastodonStatus) -> Bool {
        lhs.id == rhs.id && lhs.editedAt?.asDate == rhs.editedAt?.asDate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String
    let content: HTMLString
    let account: MastodonAccount
    let createdAt: ServerDate
    let editedAt: ServerDate?
    let reblog: MastodonReblogStatus?
    let mediaAttachments: [MastodonMediaAttachment]
    let mentions: [MastodonMention]
    let repliesCount: Int
    let reblogsCount: Int
    let favouritesCount: Int
    let tags: [MastodonTag]
    let card: MastodonCard?
    let favourited: Bool?
    let reblogged: Bool?
    let pinned: Bool?
    let bookmarked: Bool?
    let emojis: [MastodonEmoji]
    let url: String?
    let application: Application?
    let inReplyToId: String?
    let inReplyToAccountId: String?
    let visibility: Visibility
    let poll: MastodonPoll?
    let spoilerText: HTMLString
    let filtered: [MastodonFiltered]?
    let sensitive: Bool
    let language: String?

    var isHidden: Bool {
        filtered?.first?.filter.filterAction == .hide
    }

    var asMediaStatus: [MastodonMediaStatus] {
        mediaAttachments.map { .init(status: self, attachment: $0) }
    }
    init(
        id: String, content: HTMLString, account: MastodonAccount,
        createdAt: ServerDate, editedAt: ServerDate?,
        reblog: MastodonReblogStatus?,
        mediaAttachments: [MastodonMediaAttachment],
        mentions: [MastodonMention],
        repliesCount: Int, reblogsCount: Int, favouritesCount: Int,
        tags: [MastodonTag], card: MastodonCard?, favourited: Bool?,
        reblogged: Bool?, pinned: Bool?, bookmarked: Bool?,
        emojis: [MastodonEmoji], url: String?,
        application: Application?, inReplyToId: String?,
        inReplyToAccountId: String?,
        visibility: Visibility, poll: MastodonPoll?, spoilerText: HTMLString,
        filtered: [MastodonFiltered]?,
        sensitive: Bool, language: String?
    ) {
        self.id = id
        self.content = content
        self.account = account
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.reblog = reblog
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.repliesCount = repliesCount
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.tags = tags
        self.card = card
        self.favourited = favourited
        self.reblogged = reblogged
        self.pinned = pinned
        self.bookmarked = bookmarked
        self.emojis = emojis
        self.url = url
        self.application = application
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.visibility = visibility
        self.poll = poll
        self.spoilerText = spoilerText
        self.filtered = filtered
        self.sensitive = sensitive
        self.language = language
    }

    static func placeholder(forSettings: Bool = false, language: String? = nil)
        -> MastodonStatus
    {
        .init(
            id: UUID().uuidString,
            content: .init(
                stringValue:
                    "Here's to the [#crazy](#) ones. The misfits.\nThe [@rebels](#). The troublemakers.",
                parseMarkdown: forSettings),

            account: .placeholder(),
            createdAt: ServerDate(),
            editedAt: nil,
            reblog: nil,
            mediaAttachments: [],
            mentions: [],
            repliesCount: 34,
            reblogsCount: 8,
            favouritesCount: 150,
            tags: [],
            card: nil,
            favourited: false,
            reblogged: false,
            pinned: false,
            bookmarked: false,
            emojis: [],
            url: "https://example.com",
            application: nil,
            inReplyToId: nil,
            inReplyToAccountId: nil,
            visibility: .pub,
            poll: nil,
            spoilerText: .init(stringValue: ""),
            filtered: [],
            sensitive: false,
            language: language)
    }

    static func placeholders() -> [MastodonStatus] {
        [
            .placeholder(), .placeholder(), .placeholder(), .placeholder(),
            .placeholder(),
            .placeholder(), .placeholder(), .placeholder(), .placeholder(),
            .placeholder(),
        ]
    }

    var reblogAsAsStatus: MastodonStatus? {
        if let reblog {
            return .init(
                id: reblog.id,
                content: reblog.content,
                account: reblog.account,
                createdAt: reblog.createdAt,
                editedAt: reblog.editedAt,
                reblog: nil,
                mediaAttachments: reblog.mediaAttachments,
                mentions: reblog.mentions,
                repliesCount: reblog.repliesCount,
                reblogsCount: reblog.reblogsCount,
                favouritesCount: reblog.favouritesCount,
                tags: reblog.tags,
                card: reblog.card,
                favourited: reblog.favourited,
                reblogged: reblog.reblogged,
                pinned: reblog.pinned,
                bookmarked: reblog.bookmarked,
                emojis: reblog.emojis,
                url: reblog.url,
                application: reblog.application,
                inReplyToId: reblog.inReplyToId,
                inReplyToAccountId: reblog.inReplyToAccountId,
                visibility: reblog.visibility,
                poll: reblog.poll,
                spoilerText: reblog.spoilerText,
                filtered: reblog.filtered,
                sensitive: reblog.sensitive,
                language: reblog.language)
        }
        return nil
    }
}

struct MastodonReblogStatus: AnyMastodonStatus, Codable, Identifiable,
    Equatable, Hashable
{
    static func == (lhs: MastodonReblogStatus, rhs: MastodonReblogStatus)
        -> Bool
    {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String
    let content: HTMLString
    let account: MastodonAccount
    let createdAt: ServerDate
    let editedAt: ServerDate?
    let mediaAttachments: [MastodonMediaAttachment]
    let mentions: [MastodonMention]
    let repliesCount: Int
    let reblogsCount: Int
    let favouritesCount: Int
    let tags: [MastodonTag]
    let card: MastodonCard?
    let favourited: Bool?
    let reblogged: Bool?
    let pinned: Bool?
    let bookmarked: Bool?
    let emojis: [MastodonEmoji]
    let url: String?
    let application: Application?
    let inReplyToId: String?
    let inReplyToAccountId: String?
    let visibility: Visibility
    let poll: MastodonPoll?
    let spoilerText: HTMLString
    let filtered: [MastodonFiltered]?
    let sensitive: Bool
    let language: String?

    var isHidden: Bool {
        filtered?.first?.filter.filterAction == .hide
    }

    init(
        id: String, content: HTMLString, account: MastodonAccount,
        createdAt: ServerDate, editedAt: ServerDate?,
        mediaAttachments: [MastodonMediaAttachment],
        mentions: [MastodonMention], repliesCount: Int, reblogsCount: Int,
        favouritesCount: Int, tags: [MastodonTag], card: MastodonCard?,
        favourited: Bool?, reblogged: Bool?, pinned: Bool?,
        bookmarked: Bool?, emojis: [MastodonEmoji], url: String?,
        application: Application? = nil,
        inReplyToId: String?, inReplyToAccountId: String?,
        visibility: Visibility, poll: MastodonPoll?,
        spoilerText: HTMLString, filtered: [MastodonFiltered]?, sensitive: Bool,
        language: String?
    ) {
        self.id = id
        self.content = content
        self.account = account
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.repliesCount = repliesCount
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.tags = tags
        self.card = card
        self.favourited = favourited
        self.reblogged = reblogged
        self.pinned = pinned
        self.bookmarked = bookmarked
        self.emojis = emojis
        self.url = url
        self.application = application
        self.inReplyToId = inReplyToId
        self.inReplyToAccountId = inReplyToAccountId
        self.visibility = visibility
        self.poll = poll
        self.spoilerText = spoilerText
        self.filtered = filtered
        self.sensitive = sensitive
        self.language = language
    }
}
