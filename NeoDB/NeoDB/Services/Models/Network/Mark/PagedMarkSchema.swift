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

extension PagedMarkSchema {
    static var placeholders: PagedMarkSchema {
        .init(
            data: [
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
                MarkSchema.placeholder,
            ], pages: 1, count: 1)
    }
}
