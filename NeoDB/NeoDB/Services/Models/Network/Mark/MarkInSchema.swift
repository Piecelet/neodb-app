//
//  MarkInSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct MarkInSchema: Codable {
    let shelfType: ShelfType
    let visibility: Int
    let commentText: String?
    let ratingGrade: Int?
    let tags: [String]?
    let createdTime: Date?
    let postToFediverse: Bool?
}
