//
//  MastodonEmoji.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//
//  From https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
//

import Foundation

struct MastodonEmoji: Codable, Hashable, Identifiable, Equatable, Sendable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(shortcode)
    }

    var id: String {
        shortcode
    }

    let shortcode: String
    let url: URL
    let staticUrl: URL
    let visibleInPicker: Bool
    let category: String?
}
