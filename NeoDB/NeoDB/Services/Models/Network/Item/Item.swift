//
//  Item.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

// MARK: - Base Item Protocol
protocol ItemProtocol: Codable, Hashable, Identifiable {
    var id: String { get }
    var type: String { get }
    var uuid: String { get }
    var url: String { get }
    var apiUrl: String { get }
    var category: ItemCategory { get }
    var parentUuid: String? { get }
    var displayTitle: String? { get }
    var externalResources: [ItemExternalResourceSchema]? { get }
    var title: String? { get }
    var description: String? { get }
    var localizedTitle: [LocalizedTitleSchema]? { get }
    var localizedDescription: [LocalizedTitleSchema]? { get }
    var coverImageUrl: URL? { get }
    var rating: Double? { get }
    var ratingCount: Int? { get }
    var brief: String { get }
}

// Default implementation for Hashable
extension ItemProtocol {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    var toItemSchema: ItemSchema {
        return ItemSchema(
            id: self.id,
            type: self.type,
            uuid: self.uuid,
            url: self.url,
            apiUrl: self.apiUrl,
            category: self.category,
            parentUuid: self.parentUuid,
            displayTitle: self.displayTitle,
            externalResources: self.externalResources,
            title: self.title,
            description: self.description,
            localizedTitle: self.localizedTitle,
            localizedDescription: self.localizedDescription,
            coverImageUrl: self.coverImageUrl,
            rating: self.rating,
            ratingCount: self.ratingCount,
            brief: self.brief
        )
    }
}

// MARK: - Base Item Schema
struct ItemSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
}

extension ItemSchema {
    static func make(category: ItemCategory) -> any ItemProtocol.Type {
        switch category {
        case .book:
            return EditionSchema.self
        case .movie:
            return MovieSchema.self
        case .tv:
            return TVShowSchema.self
        case .tvSeason:
            return TVShowSchema.self
        case .tvEpisode:
            return TVShowSchema.self
        case .music:
            return AlbumSchema.self
        case .podcast:
            return PodcastSchema.self
        case .game:
            return GameSchema.self
        case .performance:
            return PerformanceSchema.self
        case .performanceProduction:
            return PerformanceProductionSchema.self
        default:
            return ItemSchema.self
        }
    }
}

// MARK: - Edition Schema
struct EditionSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Edition
    let subtitle: String?
    let origTitle: String?
    let author: [String]
    let translator: [String]
    let language: [String]
    let pubHouse: String?
    let pubYear: Int?
    let pubMonth: Int?
    let binding: String?
    let price: String?
    let pages: Int?
    let series: String?
    let imprint: String?
    let isbn: String?
}

// MARK: - Movie Schema
struct MovieSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Movie
    let origTitle: String?
    let otherTitle: [String]
    let director: [String]
    let playwright: [String]
    let actor: [String]
    let genre: [String]
    let language: [String]
    let area: [String]
    let year: Int?
    let site: String?
    let duration: String?
    let imdb: String?
}

// MARK: - TV Show Schema
struct TVShowSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to TV Show
    let seasonCount: Int?
    let origTitle: String?
    let otherTitle: [String]?
    let director: [String]?
    let playwright: [String]?
    let actor: [String]?
    let genre: [String]?
    let language: [String]?
    let area: [String]?
    let year: Int?
    let site: String?
    let episodeCount: Int?
    let imdb: String?
    
    // TV Season Schema
    let seasonNumber: Int?
    let episodeUuids: [String]?
    
    // TV Episode Schema
    let episodeNumber: Int?
}

// MARK: - TV Season Schema
//struct TVSeasonSchema: ItemProtocol {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String?
//    let externalResources: [ItemExternalResourceSchema]?
//    let title: String?
//    let description: String?
//    let localizedTitle: [LocalizedTitleSchema]?
//    let localizedDescription: [LocalizedTitleSchema]?
//    let coverImageUrl: URL?
//    let rating: Double?
//    let ratingCount: Int?
//    let brief: String
//    
//    // Additional properties specific to TV Season
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

// MARK: - TV Episode Schema
//struct TVEpisodeSchema: ItemProtocol {
//    let id: String
//    let type: String
//    let uuid: String
//    let url: String
//    let apiUrl: String
//    let category: ItemCategory
//    let parentUuid: String?
//    let displayTitle: String?
//    let externalResources: [ItemExternalResourceSchema]?
//    let title: String?
//    let description: String?
//    let localizedTitle: [LocalizedTitleSchema]?
//    let localizedDescription: [LocalizedTitleSchema]?
//    let coverImageUrl: URL?
//    let rating: Double?
//    let ratingCount: Int?
//    let brief: String
//    
//    // Additional properties specific to TV Episode
//    let episodeNumber: Int?
//}

// MARK: - Album Schema
struct AlbumSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Album
    let otherTitle: [String]
    let genre: [String]
    let artist: [String]
    let company: [String]
    let duration: Int?
    let releaseDate: String?
    let trackList: String?
    let barcode: String?
}

// MARK: - Podcast Schema
struct PodcastSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Podcast
    let host: [String]
    let genre: [String]
    let language: [String]
    let episodeCount: Int?
    let lastEpisodeDate: String?
    let rssUrl: String?
    let websiteUrl: String?
}

// MARK: - Game Schema
struct GameSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Game
    let genre: [String]
    let developer: [String]
    let publisher: [String]
    let platform: [String]
    let releaseType: String?
    let releaseDate: String?
    let officialSite: String?
}

// MARK: - Performance Schema
struct PerformanceSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Performance
    let origTitle: String?
    let otherTitle: [String]
    let genre: [String]
    let language: [String]
    let openingDate: String?
    let closingDate: String?
    let director: [String]
    let playwright: [String]
    let origCreator: [String]
    let composer: [String]
    let choreographer: [String]
    let performer: [String]
    let actor: [CrewMemberSchema]
    let crew: [CrewMemberSchema]
    let officialSite: String?
}

// MARK: - Performance Production Schema
struct PerformanceProductionSchema: ItemProtocol {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let apiUrl: String
    let category: ItemCategory
    let parentUuid: String?
    let displayTitle: String?
    let externalResources: [ItemExternalResourceSchema]?
    let title: String?
    let description: String?
    let localizedTitle: [LocalizedTitleSchema]?
    let localizedDescription: [LocalizedTitleSchema]?
    let coverImageUrl: URL?
    let rating: Double?
    let ratingCount: Int?
    let brief: String
    
    // Additional properties specific to Performance Production
    let origTitle: String?
    let otherTitle: [String]
    let language: [String]
    let openingDate: String?
    let closingDate: String?
    let director: [String]
    let playwright: [String]
    let origCreator: [String]
    let composer: [String]
    let choreographer: [String]
    let performer: [String]
    let actor: [CrewMemberSchema]
    let crew: [CrewMemberSchema]
    let officialSite: String?
}
