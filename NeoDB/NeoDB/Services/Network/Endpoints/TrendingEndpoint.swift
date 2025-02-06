//
//  TrendingEndpoint.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum TrendingEndpoint: NetworkEndpoint {
    case book
    case movie
    case tv
    case music
    case game
    case podcast
    case performance
    case collection
}

extension TrendingEndpoint {
    var path: String {
        switch self {
        case .book: return "/trending/book"
        case .movie: return "/trending/movie"
        case .tv: return "/trending/tv"
        case .music: return "/trending/music"
        case .game: return "/trending/game"
        case .podcast: return "/trending/podcast"
        case .performance: return "/trending/performance"
        case .collection: return "/trending/collection"
        }
    }
}