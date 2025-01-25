//
//  Item.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

private let metadataArraySeparator = " "
private let metadataArraySeparatorHidden = " "

// MARK: - Base Item Protocol
protocol ItemProtocol: Codable, Equatable, Hashable, Identifiable {
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
            metadata.append(String(format: String(localized: "metadata_book_pages_format", table: "Item", comment: "Book Pages format"), pages))
        }

        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !author.isEmpty {
            metadata.append((String(localized: "metadata_book_author_label", table: "Item", comment: "Book Author label"), author.joined(separator: metadataArraySeparator)))
        }
        if !translator.isEmpty {
            metadata.append((String(localized: "metadata_book_translator_label", table: "Item", comment: "Book Translator label"), translator.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append((String(localized: "metadata_book_language_label", table: "Item", comment: "Book Language label"), language.joined(separator: metadataArraySeparator)))
        }
        if let pubHouse = pubHouse {
            metadata.append((String(localized: "metadata_book_publisher_label", table: "Item", comment: "Book Publisher label"), pubHouse))
        }
        if let pubYear = pubYear {
            metadata.append((String(localized: "metadata_book_pub_year_label", table: "Item", comment: "Book Publication Date Year label"), String(pubYear)))
        }
        if let pubMonth = pubMonth {
            metadata.append((String(localized: "metadata_book_pub_month_label", table: "Item", comment: "Book Publication Date Month label"), String(pubMonth)))
        }
        if let binding = binding {
            metadata.append((String(localized: "metadata_book_binding_label", table: "Item", comment: "Book Binding label"), binding))
        }
        if let price = price {
            metadata.append((String(localized: "metadata_book_price_label", table: "Item", comment: "Book Price label"), price))
        }
        if let pages = pages {
            metadata.append((String(localized: "metadata_book_pages_label", table: "Item", comment: "Book Pages label"), String(pages)))
        }
        if let series = series {
            metadata.append((String(localized: "metadata_book_series_label", table: "Item", comment: "Book Series label"), series))
        }
        if let imprint = imprint {
            metadata.append((String(localized: "metadata_book_imprint_label", table: "Item", comment: "Book Imprint label"), imprint))
        }
        if let isbn = isbn {
            metadata.append((String(localized: "metadata_book_isbn_label", table: "Item", comment: "Book ISBN label"), isbn))
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
            metadata.append(area.joined(separator: metadataArraySeparatorHidden))
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
            metadata.append((String(localized: "metadata_movie_director_label", table: "Item", comment: "Movie Director label"), director.joined(separator: metadataArraySeparator)))
        }
        if !playwright.isEmpty {
            metadata.append((String(localized: "metadata_movie_playwright_label", table: "Item", comment: "Movie Playwright label"), playwright.joined(separator: metadataArraySeparator)))
        }
        if !actor.isEmpty {
            metadata.append((String(localized: "metadata_movie_actor_label", table: "Item", comment: "Movie Actor label"), actor.joined(separator: metadataArraySeparator)))
        }
        if !genre.isEmpty {
            metadata.append((String(localized: "metadata_movie_genre_label", table: "Item", comment: "Movie Genre label"), genre.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append((String(localized: "metadata_movie_language_label", table: "Item", comment: "Movie Language label"), language.joined(separator: metadataArraySeparator)))
        }
        if !area.isEmpty {
            metadata.append((String(localized: "metadata_movie_area_label", table: "Item", comment: "Movie Area label"), area.joined(separator: metadataArraySeparatorHidden)))
        }
        if let year = year {
            metadata.append((String(localized: "metadata_movie_year_label", table: "Item", comment: "Movie Year label"), String(year)))
        }
        if let duration = duration {
            metadata.append((String(localized: "metadata_movie_duration_label", table: "Item", comment: "Movie Duration label"), duration))
        }
        if let imdb = imdb {
            metadata.append((String(localized: "metadata_movie_imdb_label", table: "Item", comment: "Movie IMDB label"), imdb))
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
            metadata.append(area.joined(separator: metadataArraySeparatorHidden))
        }
        if let genre = genre, !genre.isEmpty {
            metadata.append(genre.joined(separator: metadataArraySeparator))
        }
        if let language = language, !language.isEmpty {
            metadata.append(language.joined(separator: metadataArraySeparator))
        }
        if let seasonCount = seasonCount {
            metadata.append(String(format: String(localized: "metadata_tv_season_count_format", table: "Item", comment: "TV Show Season Count format"), seasonCount))
        }
        if let episodeCount = episodeCount {
            metadata.append(String(format: String(localized: "metadata_tv_episode_count_format", table: "Item", comment: "TV Show Episode Count format"), episodeCount))
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if let director = director, !director.isEmpty {
            metadata.append((String(localized: "metadata_tv_director_label", table: "Item", comment: "TV Show Director label"), director.joined(separator: metadataArraySeparator)))
        }
        if let playwright = playwright, !playwright.isEmpty {
            metadata.append((String(localized: "metadata_tv_playwright_label", table: "Item", comment: "TV Show Playwright label"), playwright.joined(separator: metadataArraySeparator)))
        }
        if let actor = actor, !actor.isEmpty {
            metadata.append((String(localized: "metadata_tv_actor_label", table: "Item", comment: "TV Show Actor label"), actor.joined(separator: metadataArraySeparator)))
        }
        if let genre = genre, !genre.isEmpty {
            metadata.append((String(localized: "metadata_tv_genre_label", table: "Item", comment: "TV Show Genre label"), genre.joined(separator: metadataArraySeparator)))
        }
        if let language = language, !language.isEmpty {
            metadata.append((String(localized: "metadata_tv_language_label", table: "Item", comment: "TV Show Language label"), language.joined(separator: metadataArraySeparator)))
        }
        if let area = area, !area.isEmpty {
            metadata.append((String(localized: "metadata_tv_area_label", table: "Item", comment: "TV Show Area label"), area.joined(separator: metadataArraySeparatorHidden)))
        }
        if let year = year {
            metadata.append((String(localized: "metadata_tv_year_label", table: "Item", comment: "TV Show Year label"), String(year)))
        }
        if let imdb = imdb {
            metadata.append((String(localized: "metadata_tv_imdb_label", table: "Item", comment: "TV Show IMDB ID label"), imdb))
        }
        if let episodeCount = episodeCount {
            metadata.append((String(localized: "metadata_tv_episode_count_label", table: "Item", comment: "TV Show Episode Count label"), String(episodeCount)))
        }
        if let episodeNumber = episodeNumber {
            metadata.append((String(localized: "metadata_tv_episode_number_label", table: "Item", comment: "TV Show Episode Number label"), String(episodeNumber)))
        }
        if let seasonNumber = seasonNumber {
            metadata.append((String(localized: "metadata_tv_season_number_label", table: "Item", comment: "TV Show Season Number label"), String(seasonNumber)))
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

    var durationString: String? {
        if let duration = duration {
            let totalSeconds = duration / 1000  // Convert milliseconds to seconds
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return nil
    }
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
        if let durationString = durationString {
            metadata.append(durationString)
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !genre.isEmpty {
            metadata.append((String(localized: "metadata_album_genre_label", table: "Item", comment: "Album Genre label"), genre.joined(separator: metadataArraySeparator)))
        }
        if !artist.isEmpty {
            metadata.append((String(localized: "metadata_album_artist_label", table: "Item", comment: "Album Artist label"), artist.joined(separator: metadataArraySeparator)))
        }
        if !company.isEmpty {
            metadata.append((String(localized: "metadata_album_company_label", table: "Item", comment: "Album Company label"), company.joined(separator: metadataArraySeparator)))
        }
        if let durationString = durationString {
            metadata.append((String(localized: "metadata_album_duration_label", table: "Item", comment: "Album Duration label"), durationString))
        }
        if let releaseDate = releaseDate {
            metadata.append((String(localized: "metadata_album_release_date_label", table: "Item", comment: "Album Release Date label"), releaseDate))
        }
        if let trackList = trackList {
            metadata.append((String(localized: "metadata_album_track_list_label", table: "Item", comment: "Album Track List label"), trackList))
        }
        if let barcode = barcode {
            metadata.append((String(localized: "metadata_album_barcode_label", table: "Item", comment: "Album Barcode label"), barcode))
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
            metadata.append(String(format: String(localized: "metadata_podcast_episode_count_format", table: "Item", comment: "Podcast Episode Count formatted"), episodeCount))
        }
        if let lastEpisodeDate = lastEpisodeDate {
            metadata.append(lastEpisodeDate)
        }
        return metadata
    }

    var allMetadata: [(String, String)] {
        var metadata: [(String, String)] = []

        if !host.isEmpty {
            metadata.append((String(localized: "metadata_podcast_host_label", table: "Item", comment: "Podcast Host label"), host.joined(separator: metadataArraySeparator)))
        }
        if !genre.isEmpty {
            metadata.append((String(localized: "metadata_podcast_genre_label", table: "Item", comment: "Podcast Genre label"), genre.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append((String(localized: "metadata_podcast_language_label", table: "Item", comment: "Podcast Language label"), language.joined(separator: metadataArraySeparator)))
        }
        if let episodeCount = episodeCount {
            metadata.append((String(localized: "metadata_podcast_episode_count_label", table: "Item", comment: "Podcast Episode Count label"), String(episodeCount)))
        }
        if let lastEpisodeDate = lastEpisodeDate {
            metadata.append((String(localized: "metadata_podcast_last_episode_date_label", table: "Item", comment: "Podcast Last Episode Date label"), lastEpisodeDate))
        }
        if let rssUrl = rssUrl {
            metadata.append((String(localized: "metadata_podcast_rss_url_label", table: "Item", comment: "Podcast RSS URL label"), rssUrl))
        }
        if let websiteUrl = websiteUrl {
            metadata.append((String(localized: "metadata_podcast_website_url_label", table: "Item", comment: "Podcast Website URL label"), websiteUrl))
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
            metadata.append((String(localized: "metadata_game_genre_label", table: "Item", comment: "Game Genre label"), genre.joined(separator: metadataArraySeparator)))
        }
        if !developer.isEmpty {
            metadata.append((String(localized: "metadata_game_developer_label", table: "Item", comment: "Game Developer label"), developer.joined(separator: metadataArraySeparator)))
        }
        if !publisher.isEmpty {
            metadata.append((String(localized: "metadata_game_publisher_label", table: "Item", comment: "Game Publisher label"), publisher.joined(separator: metadataArraySeparator)))
        }
        if !platform.isEmpty {
            metadata.append((String(localized: "metadata_game_platform_label", table: "Item", comment: "Game Platform label"), platform.joined(separator: metadataArraySeparator)))
        }
        if let releaseType = releaseType {
            metadata.append((String(localized: "metadata_game_release_type_label", table: "Item", comment: "Game Release Type label"), releaseType))
        }
        if let releaseDate = releaseDate {
            metadata.append((String(localized: "metadata_game_release_date_label", table: "Item", comment: "Game Release Date label"), releaseDate))
        }
        if let officialSite = officialSite {
            metadata.append((String(localized: "metadata_game_official_site_label", table: "Item", comment: "Game Official Site label"), officialSite))
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
            metadata.append((String(localized: "metadata_performance_genre_label", table: "Item", comment: "Performance Genre label"), genre.joined(separator: metadataArraySeparator)))
        }
        if !language.isEmpty {
            metadata.append((String(localized: "metadata_performance_language_label", table: "Item", comment: "Performance Language label"), language.joined(separator: metadataArraySeparator)))
        }
        if let openingDate = openingDate {
            metadata.append((String(localized: "metadata_performance_opening_date_label", table: "Item", comment: "Performance Opening Date label"), openingDate))
        }
        if let closingDate = closingDate {
            metadata.append((String(localized: "metadata_performance_closing_date_label", table: "Item", comment: "Performance Closing Date label"), closingDate))
        }
        if !director.isEmpty {
            metadata.append((String(localized: "metadata_performance_director_label", table: "Item", comment: "Performance Director label"), director.joined(separator: metadataArraySeparator)))
        }
        if !playwright.isEmpty {
            metadata.append((String(localized: "metadata_performance_playwright_label", table: "Item", comment: "Performance Playwright label"), playwright.joined(separator: metadataArraySeparator)))
        }
        if !origCreator.isEmpty {
            metadata.append((String(localized: "metadata_performance_orig_creator_label", table: "Item", comment: "Performance Orig Creator label"), origCreator.joined(separator: metadataArraySeparator)))
        }
        if !composer.isEmpty {
            metadata.append((String(localized: "metadata_performance_composer_label", table: "Item", comment: "Performance Composer label"), composer.joined(separator: metadataArraySeparator)))
        }
        if !choreographer.isEmpty {
            metadata.append((String(localized: "metadata_performance_choreographer_label", table: "Item", comment: "Performance Choreographer label"), choreographer.joined(separator: metadataArraySeparator)))
        }
        if !performer.isEmpty {
            metadata.append((String(localized: "metadata_performance_performer_label", table: "Item", comment: "Performance Performer label"), performer.joined(separator: metadataArraySeparator)))
        }
        if !actor.isEmpty {
            metadata.append((String(localized: "metadata_performance_actor_label", table: "Item", comment: "Performance Actor label"), actor.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if !crew.isEmpty {
            metadata.append((String(localized: "metadata_performance_crew_label", table: "Item", comment: "Performance Crew label"), crew.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if let officialSite = officialSite {
            metadata.append((String(localized: "metadata_performance_official_site_label", table: "Item", comment: "Performance Official Site label"), officialSite))
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
            metadata.append((String(localized: "metadata_performance_production_language_label", table: "Item", comment: "Performance Production Language label"), language.joined(separator: metadataArraySeparator)))
        }
        if let openingDate = openingDate {
            metadata.append((String(localized: "metadata_performance_production_opening_date_label", table: "Item", comment: "Performance Production Opening Date label"), openingDate))
        }
        if let closingDate = closingDate {
            metadata.append((String(localized: "metadata_performance_production_closing_date_label", table: "Item", comment: "Performance Production Closing Date label"), closingDate))
        }
        if !director.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_director_label", table: "Item", comment: "Performance Production Director label"), director.joined(separator: metadataArraySeparator)))
        }
        if !playwright.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_playwright_label", table: "Item", comment: "Performance Production Playwright label"), playwright.joined(separator: metadataArraySeparator)))
        }
        if !origCreator.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_orig_creator_label", table: "Item", comment: "Performance Production Orig Creator label"), origCreator.joined(separator: metadataArraySeparator)))
        }
        if !composer.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_composer_label", table: "Item", comment: "Performance Production Composer label"), composer.joined(separator: metadataArraySeparator)))
        }
        if !choreographer.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_choreographer_label", table: "Item", comment: "Performance Production Choreographer label"), choreographer.joined(separator: metadataArraySeparator)))
        }
        if !performer.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_performer_label", table: "Item", comment: "Performance Production Performer label"), performer.joined(separator: metadataArraySeparator)))
        }
        if !actor.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_actor_label", table: "Item", comment: "Performance Production Actor label"), actor.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if !crew.isEmpty {
            metadata.append((String(localized: "metadata_performance_production_crew_label", table: "Item", comment: "Performance Production Crew label"), crew.map { $0.name }.joined(separator: metadataArraySeparator)))
        }
        if let officialSite = officialSite {
            metadata.append((String(localized: "metadata_performance_production_official_site_label", table: "Item", comment: "Performance Production Official Site label"), officialSite))
        }
        return metadata
    }
}

