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

enum MastodonVisibility: String, Codable, CaseIterable, Hashable, Equatable, Sendable {
    case pub = "public"
    case unlisted
    case priv = "private"
    case direct

    var displayName: String {
        switch self {
        case .pub:
            return String(localized: "timelines_visibility_public", table: "Timelines")
        case .unlisted:
            return String(localized: "timelines_visibility_unlisted", table: "Timelines")
        case .priv:
            return String(localized: "timelines_visibility_private", table: "Timelines")
        case .direct:
            return String(localized: "timelines_visibility_direct", table: "Timelines")
        }
    }
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
    var visibility: MastodonVisibility { get }
    var poll: MastodonPoll? { get }
    var spoilerText: HTMLString { get }
    var filtered: [MastodonFiltered]? { get }
    var sensitive: Bool { get }
    var language: String? { get }
    var isHidden: Bool { get }

    // MARK: NeoDB Private
    //    var extNeodb: [NeoDBTag] {get}
    //    var relatedWith:

    // MARK: - NeoDB

    var neodbItem: (any ItemProtocol)? { get set }
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
    var reblogsCount: Int
    var favouritesCount: Int
    let tags: [MastodonTag]
    let card: MastodonCard?
    var favourited: Bool?
    var reblogged: Bool?
    let pinned: Bool?
    var bookmarked: Bool?
    let emojis: [MastodonEmoji]
    let url: String?
    let application: Application?
    let inReplyToId: String?
    let inReplyToAccountId: String?
    let visibility: MastodonVisibility
    let poll: MastodonPoll?
    let spoilerText: HTMLString
    let filtered: [MastodonFiltered]?
    let sensitive: Bool
    let language: String?

    // MARK: - NeoDB
    var neodbItem: (any ItemProtocol)? = nil

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
        visibility: MastodonVisibility, poll: MastodonPoll?, spoilerText: HTMLString,
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(HTMLString.self, forKey: .content)
        account = try container.decode(MastodonAccount.self, forKey: .account)
        createdAt = try container.decode(ServerDate.self, forKey: .createdAt)
        editedAt = try container.decodeIfPresent(ServerDate.self, forKey: .editedAt)
        reblog = try container.decodeIfPresent(MastodonReblogStatus.self, forKey: .reblog)
        
        // Handle mediaAttachments with a default empty array if missing
        mediaAttachments = try container.decodeIfPresent([MastodonMediaAttachment].self, forKey: .mediaAttachments) ?? []
        
        mentions = try container.decode([MastodonMention].self, forKey: .mentions)
        repliesCount = try container.decode(Int.self, forKey: .repliesCount)
        reblogsCount = try container.decode(Int.self, forKey: .reblogsCount)
        favouritesCount = try container.decode(Int.self, forKey: .favouritesCount)
        tags = try container.decode([MastodonTag].self, forKey: .tags)
        card = try container.decodeIfPresent(MastodonCard.self, forKey: .card)
        favourited = try container.decodeIfPresent(Bool.self, forKey: .favourited)
        reblogged = try container.decodeIfPresent(Bool.self, forKey: .reblogged)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)
        bookmarked = try container.decodeIfPresent(Bool.self, forKey: .bookmarked)
        emojis = try container.decode([MastodonEmoji].self, forKey: .emojis)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        application = try container.decodeIfPresent(Application.self, forKey: .application)
        inReplyToId = try container.decodeIfPresent(String.self, forKey: .inReplyToId)
        inReplyToAccountId = try container.decodeIfPresent(String.self, forKey: .inReplyToAccountId)
        visibility = try container.decode(MastodonVisibility.self, forKey: .visibility)
        poll = try container.decodeIfPresent(MastodonPoll.self, forKey: .poll)
        spoilerText = try container.decode(HTMLString.self, forKey: .spoilerText)
        filtered = try container.decodeIfPresent([MastodonFiltered].self, forKey: .filtered)
        sensitive = try container.decode(Bool.self, forKey: .sensitive)
        language = try container.decodeIfPresent(String.self, forKey: .language)
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
    let visibility: MastodonVisibility
    let poll: MastodonPoll?
    let spoilerText: HTMLString
    let filtered: [MastodonFiltered]?
    let sensitive: Bool
    let language: String?

    // MARK: - NeoDB
    var neodbItem: (any ItemProtocol)? = nil

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
        visibility: MastodonVisibility, poll: MastodonPoll?,
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
