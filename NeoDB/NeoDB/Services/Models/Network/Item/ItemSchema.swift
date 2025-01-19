//
//  ItemSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

// ... existing ItemSchema implementation ...

extension ItemSchema {
    static var preview: ItemSchema {
        ItemSchema(
            id: "1",
            type: "book",
            uuid: "1",
            url: "/book/1",
            apiUrl: "https://api.example.com/item/1",
            category: .book,
            parentUuid: nil,
            displayTitle: "Sample Item",
            externalResources: nil,
            title: "Sample Item",
            description: "A sample item description",
            localizedTitle: [],
            localizedDescription: [],
            coverImageUrl: nil,
            rating: 4.5,
            ratingCount: 1234,
            brief: "A sample item brief description"
        )
    }
} 
