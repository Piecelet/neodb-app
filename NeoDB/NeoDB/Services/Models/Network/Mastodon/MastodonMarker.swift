//
//  MastodonMarker.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct MastodonMarker: Codable, Sendable {
    struct Content: Codable, Sendable {
        let lastReadId: String
        let version: Int
        let updatedAt: ServerDate
    }

    let notifications: Content?
    let home: Content?
}
