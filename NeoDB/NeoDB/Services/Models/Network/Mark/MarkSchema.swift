//
//  MarkSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

protocol AnyMarkSchema: Codable, Identifiable, Equatable, Hashable {
    // 必需的基础属性
    var shelfType: ShelfType { get }
    var visibility: MarkVisibility { get }
    var tags: [String] { get }
    
    // 可选的共享属性
    var postId: Int? { get }
    var commentText: String? { get }
    var ratingGrade: Int? { get }
    var createdTime: ServerDate? { get }
}

struct MarkSchema: AnyMarkSchema {
    let shelfType: ShelfType
    let visibility: MarkVisibility
    let postId: Int?
    let item: ItemSchema
    let createdTime: ServerDate?
    let commentText: String?
    let ratingGrade: Int?
    let tags: [String]
    
    var id: String { item.id }
}

struct MarkInSchema: AnyMarkSchema {
    let shelfType: ShelfType
    let visibility: MarkVisibility
    let commentText: String?
    let ratingGrade: Int?
    let tags: [String]
    let createdTime: ServerDate?
    let postToFediverse: Bool?
    let postId: Int?
    
    var id: String { UUID().uuidString } // 临时 ID，因为这是输入数据
}

extension MarkInSchema {
    func toMarkSchema(item: ItemSchema) -> MarkSchema {
        MarkSchema(
            shelfType: shelfType,
            visibility: visibility,
            postId: postId,
            item: item,
            createdTime: createdTime,
            commentText: commentText,
            ratingGrade: ratingGrade,
            tags: tags
        )
    }
}
