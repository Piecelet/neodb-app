//
//  ItemCategory.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ItemCategory: String, Codable, CaseIterable {
    case book
    case movie
    case tv
    case tvSeason
    case tvEpisode
    case music
    case game
    case podcast
    case performance
    case performanceProduction
    case fanfic
    case exhibition
    case collection
    
//    var rawValue: String {
//        switch self {
//        case .tvSeason, .tvEpisode:
//            return "tv"
//        case .performanceProduction:
//            return "performance"
//        default:
//            return String(describing: self)
//        }
//    }
    
    var urlPath: String {
        switch self {
        case .tvSeason, .tvEpisode:
            return "tv"
        case .performanceProduction:
            return "performance"
        default:
            return self.rawValue
        }
    }

    enum shelfAvailable: String, CaseIterable, Codable {
        case book
        case movie
        case tv
        case music
        case game
        case podcast
        case performance

        var itemCategory: ItemCategory {
            switch self {
            case .book: return .book
            case .movie: return .movie
            case .tv: return .tv
            case .music: return .music
            case .game: return .game
            case .podcast: return .podcast
            case .performance: return .performance
            }
        }

        var symbolImage: String {
            return self.itemCategory.symbolImage
        }

        var symbolImageFill: String {
            return self.itemCategory.symbolImageFill
        }

        var displayName: String {
            return self.itemCategory.displayName
        }
    }

    var symbolImage: String {
        switch self {
        case .book: return "book"
        case .movie: return "film"
        case .tv: return "tv"
        case .tvSeason: return "tv"
        case .tvEpisode: return "tv"
        case .music: return "music"
        case .game: return "gamecontroller"
        case .podcast: return "mic"
        case .performance: return "theatermasks"
        case .performanceProduction: return "theatermasks"
        case .fanfic: return "book"
        case .exhibition: return "theatermasks"
        case .collection: return "square.grid.2x2"
        }
    }

    var symbolImageFill: String {
        switch self {
        case .book: return "book.fill"
        case .movie: return "film.fill"
        case .tv: return "tv.fill"
        case .tvSeason: return "tv.fill"
        case .tvEpisode: return "tv.fill"
        case .music: return "music.note.fill"
        case .game: return "gamecontroller.fill"
        case .podcast: return "mic.fill"
        case .performance: return "theatermasks.fill"
        case .performanceProduction: return "theatermasks.fill"
        case .fanfic: return "book.fill"
        case .exhibition: return "theatermasks.fill"
        case .collection: return "square.grid.2x2.fill"
        }
    }

    var displayName: String {
        switch self {
        case .book: return "Books"
        case .movie: return "Movies"
        case .tv: return "TV Shows"
        case .tvSeason: return "TV Seasons"
        case .tvEpisode: return "TV Episodes"
        case .music: return "Music"
        case .game: return "Games"
        case .podcast: return "Podcasts"
        case .performance: return "Performances"
        case .performanceProduction: return "Performance Productions"
        case .fanfic: return "Fanfics"
        case .exhibition: return "Exhibitions"
        case .collection: return "Collections"
        }
    }
}
