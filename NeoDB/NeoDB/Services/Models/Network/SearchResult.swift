//
//  SearchResult.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct SearchResult: Codable {
    let data: [ItemSchema]
    let pages: Int
    let count: Int
}
