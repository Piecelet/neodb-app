//
//  MastodonEmoji.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
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
