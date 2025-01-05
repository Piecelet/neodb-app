import Foundation

struct Status: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let content: String
    let visibility: Visibility
    let url: String?
    let account: Account
    let mediaAttachments: [MediaAttachment]
    let mentions: [Mention]
    let tags: [Tag]
    let card: Card?
    
    enum Visibility: String, Codable {
        case `public`
        case unlisted
        case `private`
        case direct
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case content
        case visibility
        case url
        case account
        case mediaAttachments = "media_attachments"
        case mentions
        case tags
        case card
    }
}

struct Account: Codable, Identifiable {
    let id: String
    let username: String
    let displayName: String
    let avatar: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatar
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
        case id
        case type
        case url
        case previewUrl = "preview_url"
        case description
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