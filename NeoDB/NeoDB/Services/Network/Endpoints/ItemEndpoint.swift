//
//  ItemEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ItemEndpoint {
    case book(uuid: String)
    case movie(uuid: String)
    case tv(uuid: String, isSeason: Bool?, isEpisode: Bool?)
    case podcast(uuid: String)
    case album(uuid: String)
    case game(uuid: String)
    case performance(uuid: String, isProduction: Bool?)
}

extension ItemEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .book(let uuid):
            return "/book/\(uuid)"
        case .movie(let uuid):
            return "/movie/\(uuid)"
        case .tv(let uuid, let isSeason, let isEpisode):
            if isSeason != nil && isSeason! {
                return "/tv/season/\(uuid)"
            } else if isEpisode != nil && isEpisode! {
                return "/tv/episode/\(uuid)"
            } else {
                return "/tv/\(uuid)"
            }
        case .podcast(let uuid):
            return "/podcast/\(uuid)"
        case .album(let uuid):
            return "/album/\(uuid)"
        case .game(let uuid):
            return "/game/\(uuid)"
        case .performance(let uuid, let isProduction):
            if isProduction != nil && isProduction! {
                return "/performance/production/\(uuid)"
            } else {
                return "/performance/\(uuid)"
            }
        }
    }
}
