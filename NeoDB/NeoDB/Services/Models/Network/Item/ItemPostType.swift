//
//  ItemPostType.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/31/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum ItemPostType: String, Codable, Hashable, Sendable, Equatable {
    case comment
    case review
    case collection
    case mark
}
