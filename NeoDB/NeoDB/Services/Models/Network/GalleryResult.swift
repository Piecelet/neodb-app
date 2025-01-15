//
//  GalleryItems.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct GalleryResult: Codable, Identifiable {
    let name: String
    let items: [ItemSchema]
    
    var id: String {
        name
    }
}
