//
//  MarkSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct MarkSchema: Codable, Identifiable {
    let shelfType: ShelfType
    let visibility: MarkVisibility
    let postId: String?
    let item: ItemSchema
    let createdTime: ServerDate
    let commentText: String?
    let ratingGrade: Int?
    let tags: [String]
    
    var id: String { "\(item.id)_\(postId ?? createdTime)" }
}
