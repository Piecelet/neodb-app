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
    case tv(uuid: String, isSeason: Bool = false, isEpisode: Bool = false)
    case podcast(uuid: String, isEpisode: Bool = false)
    case album(uuid: String)
    case game(uuid: String)
    case performance(uuid: String, isProduction: Bool = false)
    case post(uuid: String, types: [ItemPostType])
    
    static func make(id: String, category: ItemCategory) -> ItemEndpoint {
        let uuid = id.components(separatedBy: "/").last ?? id
        switch category {
        case .book, .fanfic, .exhibition, .collection:
            return .book(uuid: uuid)
        case .movie:
            return .movie(uuid: uuid)
        case .tv:
            return .tv(uuid: uuid, isSeason: false, isEpisode: false)
        case .tvSeason:
            return .tv(uuid: uuid, isSeason: true, isEpisode: false)
        case .tvEpisode:
            return .tv(uuid: uuid, isSeason: false, isEpisode: true)
        case .music:
            return .album(uuid: uuid)
        case .game:
            return .game(uuid: uuid)
        case .podcast:
            return .podcast(uuid: uuid, isEpisode: false)
        case .podcastEpisode:
            return .podcast(uuid: uuid, isEpisode: true)
        case .performance:
            return .performance(uuid: uuid, isProduction: false)
        case .performanceProduction:
            return .performance(uuid: uuid, isProduction: true)
        }
    }
}

extension ItemEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .book(let uuid):
            return "/book/\(uuid)"
        case .movie(let uuid):
            return "/movie/\(uuid)"
        case .tv(let uuid, let isSeason, let isEpisode):
            if isSeason {
                return "/tv/season/\(uuid)"
            } else if isEpisode {
                return "/tv/episode/\(uuid)"
            } else {
                return "/tv/\(uuid)"
            }
        case .podcast(let uuid, let isEpisode):
            if isEpisode {
                return "/podcast/episode/\(uuid)"
            } else {
                return "/podcast/\(uuid)"
            }
        case .album(let uuid):
            return "/album/\(uuid)"
        case .game(let uuid):
            return "/game/\(uuid)"
        case .performance(let uuid, let isProduction):
            if isProduction {
                return "/performance/production/\(uuid)"
            } else {
                return "/performance/\(uuid)"
            }
        case .post(let uuid, _):
            return "/item/\(uuid)/posts)"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .post(_, let types):
            return [
                .init(name: "type", value: types.map { $0.rawValue }.joined(separator: ","))
            ]
        default:
            return nil
        }
    }
}
