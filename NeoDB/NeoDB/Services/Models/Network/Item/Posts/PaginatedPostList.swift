//
//  PaginatedPostList.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/30/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct PaginatedPostList: Codable, Hashable, Sendable, Equatable {
    let data: [NeoDBPost]
    let pages: Int
    let count: Int
}
