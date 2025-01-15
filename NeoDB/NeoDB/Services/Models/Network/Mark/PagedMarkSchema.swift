//
//  PagedMarkSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct PagedMarkSchema: Codable {
    let data: [MarkSchema]
    let pages: Int
    let count: Int
}
