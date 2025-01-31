//
//  ItemCategory.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import SFSafeSymbols

enum ItemCategory: String, Codable, CaseIterable {
    case book
    case movie
    case tv
    case tvSeason
    case tvEpisode
    case music
    case game
    case podcast
    case podcastEpisode = "podcastepisode"
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
        case .podcastEpisode:
            return "podcast"
        default:
            return self.rawValue
        }
    }

    enum shelfAvailable: String, CaseIterable, Codable {
        case allItems
        case book
        case movie
        case tv
        case music
        case game
        case podcast
        case performance

        var itemCategory: ItemCategory? {
            switch self {
            case .allItems: return nil
            case .book: return .book
            case .movie: return .movie
            case .tv: return .tv
            case .music: return .music
            case .game: return .game
            case .podcast: return .podcast
            case .performance: return .performance
            }
        }

        var symbolImage: Symbol {
            switch self {
            case .allItems: return .sfSymbol(.squareGrid2x2)
            default: return self.itemCategory?.symbolImage ?? .systemSymbol(self.rawValue)
            }
        }

        var symbolImageFill: Symbol {
            switch self {
            case .allItems: return .sfSymbol(.squareGrid2x2Fill)
            default: return self.itemCategory?.symbolImageFill ?? .systemSymbol(self.rawValue)
            }
        }

        var displayName: String {
            switch self {
            case .allItems: return String(localized: "category_all", table: "Item")
            default: return self.itemCategory?.displayName ?? self.rawValue
            }
        }

        var color: Color {
            switch self {
            case .allItems: return Color.accentColor
            default: return self.itemCategory?.color ?? .gray
            }
        }
    }

    enum searchable: String, CaseIterable, Codable {
        case allItems
        case book
        case movieAndTv = "movie,tv"
        case music
        case game
        case podcast
        case performance
        
        var itemCategory: ItemCategory? {
            switch self {
            case .book: return .book
            case .music: return .music
            case .game: return .game
            case .podcast: return .podcast
            case .performance: return .performance
            default: return nil
            }
        }

        var displayName: String {
            switch self {
            case .allItems: return String(localized: "category_all", table: "Item")
            case .movieAndTv: return String(localized: "category_movie_and_tv", table: "Item")
            default: return itemCategory?.displayName ?? self.rawValue
            }
        }

        var symbolImage: Symbol {
            switch self {
            case .movieAndTv: return .sfSymbol(.film)
            case .allItems: return .sfSymbol(.squareGrid2x2)
            default: return self.itemCategory?.symbolImage ?? .sfSymbol(.squareGrid2x2)
            }
        }

        var symbolImageFill: Symbol {
            switch self {
            case .movieAndTv: return .sfSymbol(.filmFill)
            case .allItems: return .sfSymbol(.squareGrid2x2Fill)
            default: return self.itemCategory?.symbolImageFill ?? .sfSymbol(.squareGrid2x2Fill)
            }
        }

        var color: Color {
            switch self {
            case .allItems: return Color.accentColor
            default: return self.itemCategory?.color ?? .gray
            }
        }
    }

    var symbolImage: Symbol {
        switch self {
        case .book: return .sfSymbol(.book)
        case .movie: return .sfSymbol(.film)
        case .tv: return .sfSymbol(.tv)
        case .tvSeason: return .sfSymbol(.tv)
        case .tvEpisode: return .sfSymbol(.tv)
        case .music: return .sfSymbol(.musicNote)
        case .game: return .systemSymbol("gamecontroller")
        case .podcast, .podcastEpisode: return .custom("custom.podcast")
        case .performance: return .sfSymbol(.theatermasks)
        case .performanceProduction: return .sfSymbol(.theatermasks)
        case .fanfic: return .sfSymbol(.book)
        case .exhibition: return .sfSymbol(.theatermasks)
        case .collection: return .sfSymbol(.squareGrid2x2)
        }
    }

    var symbolImageFill: Symbol {
        switch self {
        case .book: return .sfSymbol(.bookFill)
        case .movie: return .sfSymbol(.filmFill)
        case .tv, .tvSeason, .tvEpisode: return .sfSymbol(.tvFill)
        case .music: return .sfSymbol(.musicNote)
        case .game: return .systemSymbol("gamecontroller.fill")
        case .podcast, .podcastEpisode: return .custom("custom.podcast")
        case .performance, .performanceProduction: return .sfSymbol(.theatermasksFill)
        case .fanfic: return .sfSymbol(.bookFill)
        case .exhibition: return .sfSymbol(.theatermasksFill)
        case .collection: return .sfSymbol(.squareGrid2x2Fill)
        }
    }

    var color: Color {
        switch self {
        case .book: 
            return Color(red: 236/255, green: 138/255, blue: 37/255)  // 柔和橙色
        case .movie:
            return Color(red: 226/255, green: 62/255, blue: 87/255)   // 柔和紅色
        case .tv, .tvSeason, .tvEpisode: 
            return Color(red: 77/255, green: 75/255, blue: 186/255)   // 靛藍紫色
        case .music:
            return Color(red: 211/255, green: 82/255, blue: 73/255)   // 柔和紅色
        case .game: 
            return Color(red: 215/255, green: 153/255, blue: 33/255)  // 深金黃色
        case .podcast, .podcastEpisode: 
            return Color(red: 156/255, green: 85/255, blue: 191/255)  // 紫色
        case .performance, .performanceProduction: 
            return Color(red: 86/255, green: 112/255, blue: 154/255)  // 深藍色
        case .fanfic: 
            return Color(red: 98/255, green: 122/255, blue: 180/255)  // 柔和藍色
        case .exhibition: 
            return Color(red: 128/255, green: 128/255, blue: 128/255) // 中性灰
        case .collection: 
            return Color(red: 128/255, green: 128/255, blue: 128/255) // 中性灰
        }
    }

    var displayName: String {
        switch self {
        case .book: return String(localized: "category_books", table: "Item")
        case .movie: return String(localized: "category_movies", table: "Item")
        case .tv: return String(localized: "category_tv", table: "Item")
        case .tvSeason: return String(localized: "category_tv", table: "Item")
        case .tvEpisode: return String(localized: "category_tv", table: "Item")
        case .music: return String(localized: "category_music", table: "Item")
        case .game: return String(localized: "category_games", table: "Item")
        case .podcast, .podcastEpisode: return String(localized: "category_podcasts", table: "Item")
        case .performance: return String(localized: "category_performances", table: "Item")
        case .performanceProduction: return String(localized: "category_performances", table: "Item")
        case .fanfic: return String(localized: "category_books", table: "Item")
        case .exhibition: return String(localized: "category_performances", table: "Item")
        case .collection: return String(localized: "category_performances", table: "Item")
        }
    }
    
    var placeholderRatio: CGFloat {
        switch self {
        case .music, .podcast, .podcastEpisode: return 1/1
        default: return 3/4
        }
    }
    
    var ratio: CGFloat? {
        switch self {
        case .book, .tv, .tvSeason, .tvEpisode, .movie: return 3/4
        default: return nil
        }
    }
}

extension ItemCategory {
    var type: ItemType {
        switch self {
        case .book, .fanfic, .exhibition, .collection: return .book
        case .movie: return .movie
        case .tv: return .tv
        case .tvSeason: return .tvSeason
        case .tvEpisode: return .tvEpisode
        case .music: return .music
        case .podcast: return .podcast
        case .podcastEpisode: return .podcastEpisode
        case .game: return .game
        case .performance: return .performance
        case .performanceProduction: return .performanceProduction
        }
    }
}