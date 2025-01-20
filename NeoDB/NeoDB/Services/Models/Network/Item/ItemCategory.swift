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
            case .allItems: return "All"
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

    var symbolImage: Symbol {
        switch self {
        case .book: return .sfSymbol(.book)
        case .movie: return .sfSymbol(.film)
        case .tv: return .sfSymbol(.tv)
        case .tvSeason: return .sfSymbol(.tv)
        case .tvEpisode: return .sfSymbol(.tv)
        case .music: return .sfSymbol(.musicNote)
        case .game: return .systemSymbol("gamecontroller")
        case .podcast: return .custom("custom.podcast")
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
        case .podcast: return .custom("custom.podcast")
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
            return Color(red: 88/255, green: 86/255, blue: 214/255)   // 靛藍紫色
        case .music: 
            return Color(red: 211/255, green: 82/255, blue: 73/255)   // 柔和紅色
        case .game: 
            return Color(red: 215/255, green: 153/255, blue: 33/255)  // 深金黃色
        case .podcast: 
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
