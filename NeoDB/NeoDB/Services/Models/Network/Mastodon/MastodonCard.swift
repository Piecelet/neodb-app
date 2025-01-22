//
//  MastodonCard.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//
//  From https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
//

import Foundation

struct MastodonCard: Codable, Identifiable, Equatable, Hashable {
    var id: String {
        url
    }

    struct CardAuthor: Codable, Sendable, Identifiable, Equatable, Hashable {
        var id: String {
            url
        }

        let name: String
        let url: String
        let account: MastodonAccount?
    }

    let url: String
    let title: String?
    let authorName: String?
    let description: String?
    let providerName: String?
    let type: String
    let image: URL?
    let width: CGFloat
    let height: CGFloat
    let history: [MastodonHistory]?
    let authors: [CardAuthor]?
}

extension MastodonCard: Sendable {}
