//
//  ItemCategory.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

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

        var symbolImage: String {
            switch self {
            case .allItems: return "square.grid.2x2"
            default: return self.itemCategory?.symbolImage ?? ""
            }
        }

        var symbolImageFill: String {
            switch self {
            case .allItems: return "square.grid.2x2.fill"
            default: return self.itemCategory?.symbolImageFill ?? ""
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

    var symbolImage: String {
        switch self {
        case .book: return "book"
        case .movie: return "film"
        case .tv: return "tv"
        case .tvSeason: return "tv"
        case .tvEpisode: return "tv"
        case .music: return "music.note"
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
        case .tv, .tvSeason, .tvEpisode: return "tv.fill"
        case .music: return "music.note"
        case .game: return "gamecontroller.fill"
        case .podcast: return "mic.fill"
        case .performance, .performanceProduction: return "theatermasks.fill"
        case .fanfic: return "book.fill"
        case .exhibition: return "theatermasks.fill"
        case .collection: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .book: 
            return Color(red: 236/255, green: 138/255, blue: 37/255)  // 柔和橙色
        case .movie: 
            return Color(red: 226/255, green: 62/255, blue: 87/255)   // 柔和紅色
        case .tv, .tvSeason, .tvEpisode: 
            return Color(red: 48/255, green: 102/255, blue: 92/255)   // 深青色，接近 accent color
        case .music: 
            return Color(red: 156/255, green: 85/255, blue: 191/255)  // 柔和紫色
        case .game: 
            return Color(red: 241/255, green: 190/255, blue: 56/255)  // 溫暖金黃色
        case .podcast: 
            return Color(red: 156/255, green: 85/255, blue: 191/255) // 淺紫色
        case .performance, .performanceProduction: 
            return Color(red: 211/255, green: 82/255, blue: 73/255)   // 柔和紅褐色
        case .fanfic: 
            return Color(red: 98/255, green: 122/255, blue: 180/255)  // 柔和藍色
        case .exhibition: 
            return Color(red: 86/255, green: 112/255, blue: 154/255)  // 深藍色
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
