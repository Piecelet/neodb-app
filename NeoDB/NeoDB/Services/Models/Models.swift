//// 
////  Models.swift
////  NeoDB
////
////  Created by citron(https://github.com/lcandy2) on 1/7/25.
////
//
//import Foundation
//
//// MARK: - Item Categories
//enum ItemCategory: String, Codable, CaseIterable {
//    case book
//    case movie
//    case tv
//    case tvSeason = "tv_season"
//    case tvEpisode = "tv_episode"
//    case music
//    case game
//    case podcast
//    case performance
//    case fanfic
//    case exhibition
//    case collection
//}
//
//// MARK: - Shelf Types
//enum ShelfType: String, Codable, CaseIterable {
//    case wishlist
//    case progress
//    case complete
//    case dropped
//    
//    var displayName: String {
//        switch self {
//        case .wishlist:
//            return "Want to Read"
//        case .progress:
//            return "Reading"
//        case .complete:
//            return "Completed"
//        case .dropped:
//            return "Dropped"
//        }
//    }
//    
//    var systemImage: String {
//        switch self {
//        case .wishlist:
//            return "star"
//        case .progress:
//            return "book"
//        case .complete:
//            return "checkmark.circle"
//        case .dropped:
//            return "xmark.circle"
//        }
//    }
//}
//
//// MARK: - Base Item Schema
//struct ItemSchema: Codable, Hashable {
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let brief: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case title, description, type, id, uuid, url, category, rating
//        case localizedTitle = "localized_title"
//        case localizedDescription = "localized_description"
//        case coverImageUrl = "cover_image_url"
//        case ratingCount = "rating_count"
//        case apiUrl = "api_url"
//        case parentUuid = "parent_uuid"
//        case displayTitle = "display_title"
//        case externalResources = "external_resources"
//        case brief
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//    
//    static func == (lhs: ItemSchema, rhs: ItemSchema) -> Bool {
//        lhs.id == rhs.id
//    }
//}
//
//// MARK: - Localized Title
//struct LocalizedTitleSchema: Codable {
//    let lang: String
//    let text: String
//}
//
//// MARK: - External Resource
//struct ExternalResourceSchema: Codable {
//    let url: String
//}
//
//// MARK: - Crew Member
//struct CrewMemberSchema: Codable {
//    let name: String
//    let role: String?
//}
//
//// MARK: - Edition Schema
//struct EditionSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let subtitle: String?
//    let origTitle: String?
//    let author: [String]
//    let translator: [String]
//    let language: [String]
//    let pubHouse: String?
//    let pubYear: Int?
//    let pubMonth: Int?
//    let binding: String?
//    let price: String?
//    let pages: Int?
//    let series: String?
//    let imprint: String?
//    let isbn: String?
//}
//
//// MARK: - Movie Schema
//struct MovieSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let origTitle: String?
//    let otherTitle: [String]
//    let director: [String]
//    let playwright: [String]
//    let actor: [String]
//    let genre: [String]
//    let language: [String]
//    let area: [String]
//    let year: Int?
//    let site: String?
//    let duration: String?
//    let imdb: String?
//}
//
//// MARK: - TV Show Schema
//struct TVShowSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let seasonCount: Int?
//    let origTitle: String?
//    let otherTitle: [String]
//    let director: [String]
//    let playwright: [String]
//    let actor: [String]
//    let genre: [String]
//    let language: [String]
//    let area: [String]
//    let year: Int?
//    let site: String?
//    let episodeCount: Int?
//    let imdb: String?
//}
//
//// MARK: - TV Season Schema
//struct TVSeasonSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let seasonNumber: Int?
//    let origTitle: String?
//    let otherTitle: [String]
//    let director: [String]
//    let playwright: [String]
//    let actor: [String]
//    let genre: [String]
//    let language: [String]
//    let area: [String]
//    let year: Int?
//    let site: String?
//    let episodeCount: Int?
//    let episodeUuids: [String]
//    let imdb: String?
//}
//
//// MARK: - TV Episode Schema
//struct TVEpisodeSchema: Codable {
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let episodeNumber: Int?
//}
//
//// MARK: - Album Schema
//struct AlbumSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let otherTitle: [String]
//    let genre: [String]
//    let artist: [String]
//    let company: [String]
//    let duration: Int?
//    let releaseDate: String?
//    let trackList: String?
//    let barcode: String?
//}
//
//// MARK: - Podcast Schema
//struct PodcastSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let host: [String]
//    let genre: [String]
//    let language: [String]
//    let episodeCount: Int?
//    let lastEpisodeDate: String?
//    let rssUrl: String?
//    let websiteUrl: String?
//}
//
//// MARK: - Game Schema
//struct GameSchema: Codable {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let genre: [String]
//    let developer: [String]
//    let publisher: [String]
//    let platform: [String]
//    let releaseType: String?
//    let releaseDate: String?
//    let officialSite: String?
//}
//
//// MARK: - Performance Schema
//struct PerformanceSchema: Codable {
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let origTitle: String?
//    let otherTitle: [String]
//    let genre: [String]
//    let language: [String]
//    let openingDate: String?
//    let closingDate: String?
//    let director: [String]
//    let playwright: [String]
//    let origCreator: [String]
//    let composer: [String]
//    let choreographer: [String]
//    let performer: [String]
//    let actor: [CrewMemberSchema]
//    let crew: [CrewMemberSchema]
//    let officialSite: String?
//}
//
//// MARK: - Performance Production Schema
//struct PerformanceProductionSchema: Codable {
//    let title: String
//    let description: String
//    let localizedTitle: [LocalizedTitleSchema]
//    let localizedDescription: [LocalizedTitleSchema]
//    let coverImageUrl: String?
//    let rating: Double?
//    let ratingCount: Int?
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String
//    let externalResources: [ExternalResourceSchema]?
//    let origTitle: String?
//    let otherTitle: [String]
//    let language: [String]
//    let openingDate: String?
//    let closingDate: String?
//    let director: [String]
//    let playwright: [String]
//    let origCreator: [String]
//    let composer: [String]
//    let choreographer: [String]
//    let performer: [String]
//    let actor: [CrewMemberSchema]
//    let crew: [CrewMemberSchema]
//    let officialSite: String?
//}
//
//// MARK: - Mark Schema
//struct MarkSchema: Codable, Identifiable {
//    var id: String { item.uuid }
//    let shelfType: ShelfType
//    let visibility: Int
//    let item: ItemSchema
//    let createdTime: Date
//    let commentText: String?
//    let ratingGrade: Int?
//    let tags: [String]
//    
//    enum CodingKeys: String, CodingKey {
//        case shelfType = "shelf_type"
//        case visibility
//        case item
//        case createdTime = "created_time"
//        case commentText = "comment_text"
//        case ratingGrade = "rating_grade"
//        case tags
//    }
//}
//
//// MARK: - Paged Mark Schema
//struct PagedMarkSchema: Codable {
//    let data: [MarkSchema]
//    let pages: Int
//    let count: Int
//}
//
//// MARK: - Redirected Result
//struct RedirectedResult: Codable {
//    let message: String?
//    let url: String
//}
