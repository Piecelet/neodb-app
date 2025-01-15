//
//  Item.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

// MARK: - Base Item Schema
struct ItemSchema: Codable, Hashable {
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let brief: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ItemSchema, rhs: ItemSchema) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Edition Schema
struct EditionSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let subtitle: String?
    let orig_title: String?
    let author: [String]
    let translator: [String]
    let language: [String]
    let pub_house: String?
    let pub_year: Int?
    let pub_month: Int?
    let binding: String?
    let price: String?
    let pages: Int?
    let series: String?
    let imprint: String?
    let isbn: String?
}

// MARK: - Movie Schema
struct MovieSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let orig_title: String?
    let other_title: [String]
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
struct TVShowSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let season_count: Int?
    let orig_title: String?
    let other_title: [String]
    let director: [String]
    let playwright: [String]
    let actor: [String]
    let genre: [String]
    let language: [String]
    let area: [String]
    let year: Int?
    let site: String?
    let episode_count: Int?
    let imdb: String?
}

// MARK: - TV Season Schema
struct TVSeasonSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let season_number: Int?
    let orig_title: String?
    let other_title: [String]
    let director: [String]
    let playwright: [String]
    let actor: [String]
    let genre: [String]
    let language: [String]
    let area: [String]
    let year: Int?
    let site: String?
    let episode_count: Int?
    let episode_uuids: [String]
    let imdb: String?
}

// MARK: - TV Episode Schema
struct TVEpisodeSchema: Codable {
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let episode_number: Int?
}

// MARK: - Album Schema
struct AlbumSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let other_title: [String]
    let genre: [String]
    let artist: [String]
    let company: [String]
    let duration: Int?
    let release_date: String?
    let track_list: String?
    let barcode: String?
}

// MARK: - Podcast Schema
struct PodcastSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let host: [String]
    let genre: [String]
    let language: [String]
    let episode_count: Int?
    let last_episode_date: String?
    let rss_url: String?
    let website_url: String?
}

// MARK: - Game Schema
struct GameSchema: Codable {
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let genre: [String]
    let developer: [String]
    let publisher: [String]
    let platform: [String]
    let release_type: String?
    let release_date: String?
    let official_site: String?
}

// MARK: - Performance Schema
struct PerformanceSchema: Codable {
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let orig_title: String?
    let other_title: [String]
    let genre: [String]
    let language: [String]
    let opening_date: String?
    let closing_date: String?
    let director: [String]
    let playwright: [String]
    let orig_creator: [String]
    let composer: [String]
    let choreographer: [String]
    let performer: [String]
    let actor: [CrewMemberSchema]
    let crew: [CrewMemberSchema]
    let official_site: String?
}

// MARK: - Performance Production Schema
struct PerformanceProductionSchema: Codable {
    let title: String
    let description: String
    let localized_title: [LocalizedTitleSchema]
    let localized_description: [LocalizedTitleSchema]
    let cover_image_url: String?
    let rating: Double?
    let rating_count: Int?
    let id: String
    let type: String
    let uuid: String
    let url: String
    let api_url: String
    let category: ItemCategory
    let parent_uuid: String?
    let display_title: String
    let external_resources: [ExternalResourceSchema]?
    let orig_title: String?
    let other_title: [String]
    let language: [String]
    let opening_date: String?
    let closing_date: String?
    let director: [String]
    let playwright: [String]
    let orig_creator: [String]
    let composer: [String]
    let choreographer: [String]
    let performer: [String]
    let actor: [CrewMemberSchema]
    let crew: [CrewMemberSchema]
    let official_site: String?
}
