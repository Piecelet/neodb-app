//
//  ItemType.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

enum ItemType: String, Codable, CaseIterable {
    case book = "edition"
    case movie
    case tv = "tvshow"
    case tvSeason = "tvseason"
    case tvEpisode = "TVEpisode"
    case music
    case podcast
    case podcastEpisode = "podcastepisode"
    case game
    case performance = "Performance"
    case performanceProduction = "PerformanceProduction"
}

extension ItemType {
    var category: ItemCategory {
        switch self {
        case .book:
            return .book
        case .movie:
            return .movie
        case .tv:
            return .tv
        case .tvSeason:
            return .tvSeason
        case .tvEpisode:
            return .tvEpisode
        case .music:
            return .music
        case .podcast:
            return .podcast
        case .podcastEpisode:
            return .podcastEpisode
        case .game:
            return .game
        case .performance:
            return .performance
        case .performanceProduction:
            return .performanceProduction
        }
    }
}