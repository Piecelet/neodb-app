//
//  MarkSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct MarkSchema: Codable {
    let shelfType: ShelfType
    let visibility: Int
    let item: ItemSchema
    let createdTime: Date
    let commentText: String?
    let ratingGrade: Int?
    let tags: [String]
}
