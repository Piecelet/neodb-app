import Foundation

enum ShelfType: String, Codable, CaseIterable {
    case wishlist
    case progress
    case complete
    case dropped
    
    var displayName: String {
        switch self {
        case .wishlist: return "Want to Read"
        case .progress: return "Reading"
        case .complete: return "Completed"
        case .dropped: return "Dropped"
        }
    }
    
    var systemImage: String {
        switch self {
        case .wishlist: return "star"
        case .progress: return "book"
        case .complete: return "checkmark.circle"
        case .dropped: return "xmark.circle"
        }
    }
}

enum ItemCategory: String, Codable {
    case book, movie, tv, music, game, podcast
    case performance, fanfic, exhibition, collection
}

struct PagedMarkSchema: Codable {
    let data: [MarkSchema]
    let pages: Int
    let count: Int
}

struct MarkSchema: Codable, Identifiable {
    var id: String { item.uuid }
    let shelfType: ShelfType
    let visibility: Int
    let item: ItemSchema
    let createdTime: Date
    let commentText: String?
    let ratingGrade: Int?
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case shelfType = "shelf_type"
        case visibility
        case item
        case createdTime = "created_time"
        case commentText = "comment_text"
        case ratingGrade = "rating_grade"
        case tags
    }
}

struct ItemSchema: Codable {
    let title: String
    let description: String
    let localizedTitle: [LocalizedTitle]
    let localizedDescription: [LocalizedTitle]
    let coverImageUrl: String?
    let rating: Double?
    let ratingCount: Int?
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String
    let externalResources: [ExternalResource]?
    
    enum CodingKeys: String, CodingKey {
        case title, description, type, id, uuid, url, category
        case localizedTitle = "localized_title"
        case localizedDescription = "localized_description"
        case coverImageUrl = "cover_image_url"
        case ratingCount = "rating_count"
        case apiUrl = "api_url"
        case parentUuid = "parent_uuid"
        case displayTitle = "display_title"
        case externalResources = "external_resources"
        case rating
    }
}

struct LocalizedTitle: Codable {
    let lang: String
    let text: String
}

struct ExternalResource: Codable {
    let url: String
} 
