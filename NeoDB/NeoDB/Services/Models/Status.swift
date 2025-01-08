import Foundation

class Status: Codable, Identifiable {
    let id: String
    let uri: String
    let createdAt: Date
    let editedAt: Date?
    let content: String
    let text: String
    let visibility: Visibility
    let sensitive: Bool
    let spoilerText: String
    let url: String
    let account: Account
    let mediaAttachments: [MediaAttachment]
    let mentions: [Mention]
    let tags: [Tag]
    let card: Card?
    let language: String?
    let favourited: Bool
    let reblogged: Bool
    let muted: Bool
    let bookmarked: Bool
    let pinned: Bool
    let reblog: Status?
    let favouritesCount: Int
    let reblogsCount: Int
    let repliesCount: Int
    
    enum Visibility: String, Codable {
        case `public`
        case unlisted
        case `private`
        case direct
    }
    
    enum CodingKeys: String, CodingKey {
        case id, uri, content, text, visibility, sensitive, url, account, mentions, tags, card, language
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case spoilerText = "spoiler_text"
        case mediaAttachments = "media_attachments"
        case favourited, reblogged, muted, bookmarked, pinned, reblog
        case favouritesCount = "favourites_count"
        case reblogsCount = "reblogs_count"
        case repliesCount = "replies_count"
    }
}

struct Account: Codable, Identifiable {
    let id: String
    let username: String
    let acct: String
    let url: String
    let displayName: String
    let note: String
    let avatar: String
    let avatarStatic: String
    let header: String
    let headerStatic: String
    let locked: Bool
    let bot: Bool
    let group: Bool
    let discoverable: Bool
    let indexable: Bool
    let statusesCount: Int
    let followersCount: Int
    let followingCount: Int
    let createdAt: Date
    let lastStatusAt: String?
    let fields: [Field]
    let emojis: [Emoji]
    
    enum CodingKeys: String, CodingKey {
        case id, username, acct, url, note, avatar, locked, bot, group, fields, emojis
        case displayName = "display_name"
        case avatarStatic = "avatar_static"
        case header, headerStatic = "header_static"
        case discoverable, indexable
        case statusesCount = "statuses_count"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case createdAt = "created_at"
        case lastStatusAt = "last_status_at"
    }
}

struct Field: Codable {
    let name: String
    let value: String
    let verifiedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case name, value
        case verifiedAt = "verified_at"
    }
}

struct Emoji: Codable {
    let shortcode: String
    let url: String
    let staticUrl: String
    let visibleInPicker: Bool
    
    enum CodingKeys: String, CodingKey {
        case shortcode, url
        case staticUrl = "static_url"
        case visibleInPicker = "visible_in_picker"
    }
}

struct MediaAttachment: Codable, Identifiable {
    let id: String
    let type: MediaType
    let url: String
    let previewUrl: String?
    let description: String?
    
    enum MediaType: String, Codable {
        case image
        case video
        case gifv
        case audio
        case unknown
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, url, description
        case previewUrl = "preview_url"
    }
}

struct Mention: Codable {
    let username: String
    let url: String
    let acct: String
}

struct Tag: Codable {
    let name: String
    let url: String
}

struct Card: Codable {
    let url: String
    let title: String
    let description: String
    let image: String?
} 