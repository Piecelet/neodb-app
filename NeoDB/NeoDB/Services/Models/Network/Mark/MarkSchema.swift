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
    var commentText: String { get }
    
    // 可选的共享属性
    var postId: Int? { get }
    var ratingGrade: Int? { get }
    var createdTime: ServerDate? { get }
}

struct MarkSchema: AnyMarkSchema {
    let shelfType: ShelfType
    let visibility: MarkVisibility
    let postId: Int?
    let item: ItemSchema
    let createdTime: ServerDate?
    let commentText: String
    let ratingGrade: Int?
    let tags: [String]
    
    var id: String {
        let components = [
            postId.map { "p\($0)" },
            "i\(item.id)",
            "t\(shelfType.rawValue)",
            createdTime.map { "c\($0)" }
        ].compactMap { $0 }
        
        return components.joined(separator: "_")
    }
    
    enum CodingKeys: CodingKey {
        case shelfType
        case visibility
        case postId
        case item
        case createdTime
        case commentText
        case ratingGrade
        case tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        shelfType = try container.decode(ShelfType.self, forKey: .shelfType)
        visibility = try container.decode(MarkVisibility.self, forKey: .visibility)
        postId = try container.decodeIfPresent(Int.self, forKey: .postId)
        item = try container.decode(ItemSchema.self, forKey: .item)
        createdTime = try container.decodeIfPresent(ServerDate.self, forKey: .createdTime)
        commentText = try container.decodeIfPresent(String.self, forKey: .commentText) ?? ""
        ratingGrade = try container.decodeIfPresent(Int.self, forKey: .ratingGrade)
        tags = try container.decode([String].self, forKey: .tags)
    }
    
    init(shelfType: ShelfType, visibility: MarkVisibility, postId: Int?, item: ItemSchema, createdTime: ServerDate?, commentText: String?, ratingGrade: Int?, tags: [String]) {
        self.shelfType = shelfType
        self.visibility = visibility
        self.postId = postId
        self.item = item
        self.createdTime = createdTime
        self.commentText = commentText ?? ""
        self.ratingGrade = ratingGrade
        self.tags = tags
    }
}

extension MarkSchema {
    static var placeholder: MarkSchema {
        .init(
            shelfType: .wishlist,
            visibility: .pub,
            postId: nil,
            item: .placeholder,
            createdTime: ServerDate(),
            commentText: "",
            ratingGrade: nil,
            tags: []
        )
    }
}

struct MarkInSchema: AnyMarkSchema {
    let shelfType: ShelfType
    let visibility: MarkVisibility
    let commentText: String
    let ratingGrade: Int?
    let tags: [String]
    let createdTime: ServerDate?
    let postToFediverse: Bool?
    let postId: Int?
    
    var id: String { UUID().uuidString } // 临时 ID，因为这是输入数据
    
    init(shelfType: ShelfType, visibility: MarkVisibility, commentText: String?, ratingGrade: Int?, tags: [String], createdTime: ServerDate?, postToFediverse: Bool?, postId: Int?) {
        self.shelfType = shelfType
        self.visibility = visibility
        self.commentText = commentText ?? ""
        self.ratingGrade = ratingGrade
        self.tags = tags
        self.createdTime = createdTime
        self.postToFediverse = postToFediverse
        self.postId = postId
    }
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
