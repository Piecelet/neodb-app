//
//  MastodonFiltered.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//
//  From https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
//

import Foundation

public struct MastodonFiltered: Codable, Equatable, Hashable {
    public let filter: MastodonFilter
    public let keywordMatches: [String]?
}

public struct MastodonFilter: Codable, Identifiable, Equatable, Hashable {
    public enum Action: String, Codable, Equatable {
        case warn, hide
    }

    public enum Context: String, Codable {
        case home, notifications, account, thread
        case pub = "public"
    }

    public let id: String
    public let title: String
    public let context: [String]
    public let filterAction: Action
}

extension MastodonFiltered: Sendable {}
extension MastodonFilter: Sendable {}
extension MastodonFilter.Action: Sendable {}
extension MastodonFilter.Context: Sendable {}
