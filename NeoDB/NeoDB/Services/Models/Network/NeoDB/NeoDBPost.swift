//
//  NeoDBPosts.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/30/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct NeoDBPost: Codable, Identifiable, Hashable, Sendable, Equatable {
    var id: String
    let uri: String
    let createdAt: String
    let account: NeoDBAccount
    let content: String
    let visibility: String
    let sensitive: Bool
    let spoilerText: String
    let mentions: [NeoDBMention]
    let tags: [NeoDBTag]
    let emojis: [NeoDBEmoji]
    let reblogsCount: Int
    let favouritesCount: Int
    let repliesCount: Int
    let url: String?
    let inReplyToId: String?
    let inReplyToAccountId: String?
    let language: String?
    let text: String?
    let editedAt: String?
    let favourited: Bool?
    let reblogged: Bool?
    let muted: Bool?
    let bookmarked: Bool?
    let pinned: Bool?
    // let extNeodb: JSONValue?
}
