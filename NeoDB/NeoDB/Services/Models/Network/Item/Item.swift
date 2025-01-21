//
//  Item.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

private let metadataArraySeparator = ", "

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

extension EditionSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if let author = author.first {
            metadata.append(author)
        }
        if let pubHouse = pubHouse {
            metadata.append(pubHouse)
        }
        if let pubYear = pubYear {
            metadata.append(String(pubYear))
        }
        if let pages = pages {
            metadata.append("\(pages) pages")
        }

        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !author.isEmpty {
            metadata.append(("Author", author.joined(separator: metadataArraySeparator)))
        }
        if !translator.isEmpty {
            metadata.append(("Translator", translator.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append(("Language", language.joined(separator: metadataArraySeparator)))
        }
        if let pubHouse = pubHouse {
            metadata.append(("Publisher", pubHouse))
        }
        if let pubYear = pubYear {
            metadata.append(("Year", String(pubYear)))
        }
        if let pubMonth = pubMonth {
            metadata.append(("Month", String(pubMonth)))
        }
        if let binding = binding {
            metadata.append(("Binding", binding))
        }
        if let price = price {
            metadata.append(("Price", price))
        }
        if let pages = pages {
            metadata.append(("Pages", String(pages)))
        }
        if let series = series {
            metadata.append(("Series", series))
        }
        if let imprint = imprint {
            metadata.append(("Imprint", imprint))
        }
        if let isbn = isbn {
            metadata.append(("ISBN", isbn))
        }
        return metadata
    }
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

extension MovieSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if !area.isEmpty {
            metadata.append(area.joined(separator: metadataArraySeparator))
        }
        if !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        if !language.isEmpty {
            metadata.append(language.joined(separator: metadataArraySeparator))
        }
        if let duration = duration {
            metadata.append(duration)
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !director.isEmpty {
            metadata.append(("Director", director.joined(separator: metadataArraySeparator)))
        }
        if !playwright.isEmpty {
            metadata.append(("Playwright", playwright.joined(separator: metadataArraySeparator)))
        }
        if !actor.isEmpty {
            metadata.append(("Actor", actor.joined(separator: metadataArraySeparator)))
        }
        if !genre.isEmpty {
            metadata.append(("Genre", genre.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append(("Language", language.joined(separator: metadataArraySeparator)))
        }
        if !area.isEmpty {
            metadata.append(("Area", area.joined(separator: metadataArraySeparator)))
        }
        if let year = year {
            metadata.append(("Year", String(year)))
        }
        if let duration = duration {
            metadata.append(("Duration", duration))
        }
        if let imdb = imdb {
            metadata.append(("IMDB", imdb))
        }
        return metadata
    }
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

extension TVShowSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if let area = area, !area.isEmpty {
            metadata.append(area.joined(separator: metadataArraySeparator))
        }
        if let genre = genre, !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        if let language = language, !language.isEmpty {
            metadata.append(language.joined(separator: metadataArraySeparator))
        }
        if let seasonCount = seasonCount {
            metadata.append("\(seasonCount) seasons")
        }
        if let episodeCount = episodeCount {
            metadata.append("\(episodeCount) episodes")
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if let director = director, !director.isEmpty {
            metadata.append(("Director", director.joined(separator: metadataArraySeparator)))
        }
        if let playwright = playwright, !playwright.isEmpty {
            metadata.append(("Playwright", playwright.joined(separator: metadataArraySeparator)))
        }
        if let actor = actor, !actor.isEmpty {
            metadata.append(("Actor", actor.joined(separator: metadataArraySeparator)))
        }
        if let genre = genre, !genre.isEmpty {
            metadata.append(("Genre", genre.joined(separator: metadataArraySeparator)))
        }
        if let language = language, !language.isEmpty {
            metadata.append(("Language", language.joined(separator: metadataArraySeparator)))
        }
        if let area = area, !area.isEmpty {
            metadata.append(("Area", area.joined(separator: metadataArraySeparator)))
        }
        if let year = year {
            metadata.append(("Year", String(year)))
        }
        if let imdb = imdb {
            metadata.append(("IMDB", imdb))
        }
        if let episodeCount = episodeCount {
            metadata.append(("Episode Count", String(episodeCount)))
        }
        if let episodeNumber = episodeNumber {
            metadata.append(("Episode Number", String(episodeNumber)))
        }
        if let seasonNumber = seasonNumber {
            metadata.append(("Season Number", String(seasonNumber)))
        }
        return metadata
    }
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

extension AlbumSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if !artist.isEmpty {
            metadata.append(artist.joined(separator: metadataArraySeparator))
        }
        if !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        if let releaseDate = releaseDate {
            metadata.append(releaseDate)
        }
        if let duration = duration {
            metadata.append("\(duration) minutes")
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !genre.isEmpty {
            metadata.append(("Genre", genre.joined(separator: metadataArraySeparator)))
        }
        if !artist.isEmpty {
            metadata.append(("Artist", artist.joined(separator: metadataArraySeparator)))
        }
        if !company.isEmpty {
            metadata.append(("Company", company.joined(separator: metadataArraySeparator)))
        }
        if let duration = duration {
            metadata.append(("Duration", "\(duration) minutes"))
        }
        if let releaseDate = releaseDate {
            metadata.append(("Release Date", releaseDate))
        }
        if let trackList = trackList {
            metadata.append(("Track List", trackList))
        }
        if let barcode = barcode {
            metadata.append(("Barcode", barcode))
        }
        return metadata
    }
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

extension PodcastSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if !host.isEmpty {
            metadata.append(host.joined(separator: metadataArraySeparator))
        }
        if !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        if !language.isEmpty {
            metadata.append(language.joined(separator: metadataArraySeparator))
        }
        if let episodeCount = episodeCount {
            metadata.append("\(episodeCount) episodes")
        }
        if let lastEpisodeDate = lastEpisodeDate {
            metadata.append(lastEpisodeDate)
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !host.isEmpty {
            metadata.append(("Host", host.joined(separator: metadataArraySeparator)))
        }
        if !genre.isEmpty {
            metadata.append(("Genre", genre.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append(("Language", language.joined(separator: metadataArraySeparator)))
        }
        if let episodeCount = episodeCount {
            metadata.append(("Episode Count", String(episodeCount)))
        }
        if let lastEpisodeDate = lastEpisodeDate {
            metadata.append(("Last Episode Date", lastEpisodeDate))
        }
        if let rssUrl = rssUrl {
            metadata.append(("RSS URL", rssUrl))
        }
        if let websiteUrl = websiteUrl {
            metadata.append(("Website URL", websiteUrl))
        }
        return metadata
    }
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

extension GameSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        if !platform.isEmpty {
            metadata.append(platform.joined(separator: metadataArraySeparator))
        }
        if !developer.isEmpty {
            metadata.append(developer.joined(separator: metadataArraySeparator))
        }
        if !publisher.isEmpty {
            metadata.append(publisher.joined(separator: metadataArraySeparator))
        }
        if let releaseDate = releaseDate {
            metadata.append(releaseDate)
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !genre.isEmpty {
            metadata.append(("Genre", genre.joined(separator: metadataArraySeparator)))
        }
        if !developer.isEmpty {
            metadata.append(("Developer", developer.joined(separator: metadataArraySeparator)))
        }
        if !publisher.isEmpty {
            metadata.append(("Publisher", publisher.joined(separator: metadataArraySeparator)))
        }
        if !platform.isEmpty {
            metadata.append(("Platform", platform.joined(separator: metadataArraySeparator)))
        }
        if let releaseType = releaseType {
            metadata.append(("Release Type", releaseType))
        }
        if let releaseDate = releaseDate {
            metadata.append(("Release Date", releaseDate))
        }
        if let officialSite = officialSite {
            metadata.append(("Official Site", officialSite))
        }
        return metadata
    }
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

extension PerformanceSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !genre.isEmpty {
            metadata.append(("Genre", genre.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append(("Language", language.joined(separator: metadataArraySeparator)))
        }
        if let openingDate = openingDate {
            metadata.append(("Opening Date", openingDate))
        }
        if let closingDate = closingDate {
            metadata.append(("Closing Date", closingDate))
        }
        if !director.isEmpty {
            metadata.append(("Director", director.joined(separator: metadataArraySeparator)))
        }
        if !playwright.isEmpty {
            metadata.append(("Playwright", playwright.joined(separator: metadataArraySeparator)))
        }
        if !origCreator.isEmpty {
            metadata.append(("Orig Creator", origCreator.joined(separator: metadataArraySeparator)))
        }
        if !composer.isEmpty {
            metadata.append(("Composer", composer.joined(separator: metadataArraySeparator)))
        }
        if !choreographer.isEmpty {
            metadata.append(("Choreographer", choreographer.joined(separator: metadataArraySeparator)))
        }
        if !performer.isEmpty {
            metadata.append(("Performer", performer.joined(separator: metadataArraySeparator)))
        }
        if !actor.isEmpty {
            metadata.append(("Actor", actor.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if !crew.isEmpty {
            metadata.append(("Crew", crew.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if let officialSite = officialSite {
            metadata.append(("Official Site", officialSite))
        }
        return metadata
    }
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

extension PerformanceProductionSchema {
    var keyMetadata: [String] {
        var metadata: [String] = []

        if !language.isEmpty {
            metadata.append(language.joined(separator: metadataArraySeparator))
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !language.isEmpty {
            metadata.append(("Language", language.joined(separator: metadataArraySeparator)))
        }
        if let openingDate = openingDate {
            metadata.append(("Opening Date", openingDate))
        }
        if let closingDate = closingDate {
            metadata.append(("Closing Date", closingDate))
        }
        if !director.isEmpty {
            metadata.append(("Director", director.joined(separator: metadataArraySeparator)))
        }
        if !playwright.isEmpty {
            metadata.append(("Playwright", playwright.joined(separator: metadataArraySeparator)))
        }
        if !origCreator.isEmpty {
            metadata.append(("Orig Creator", origCreator.joined(separator: metadataArraySeparator)))
        }
        if !composer.isEmpty {
            metadata.append(("Composer", composer.joined(separator: metadataArraySeparator)))
        }
        if !choreographer.isEmpty {
            metadata.append(("Choreographer", choreographer.joined(separator: metadataArraySeparator)))
        }
        if !performer.isEmpty {
            metadata.append(("Performer", performer.joined(separator: metadataArraySeparator)))
        }
        if !actor.isEmpty {
            metadata.append(("Actor", actor.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if !crew.isEmpty {
            metadata.append(("Crew", crew.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if let officialSite = officialSite {
            metadata.append(("Official Site", officialSite))
        }
        return metadata
    }
}

