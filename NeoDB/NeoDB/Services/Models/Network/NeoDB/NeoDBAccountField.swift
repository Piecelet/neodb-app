//
//  NeoDBAccountField.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/30/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct NeoDBAccountField:  Codable, Identifiable, Sendable, Equatable, Hashable {
    var id: String {
        value + name
    }
    let name: String
    let value: String
    let verifiedAt: String?
}
