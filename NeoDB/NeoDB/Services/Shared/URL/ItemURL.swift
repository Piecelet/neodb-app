//
//  ItemURL.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ItemURL {
    static func makeShareURL(for item: any ItemProtocol, instance: String) -> URL? {
        guard let url = URL(string: item.url) else { return nil }
        
        if url.host == nil {
            return URL(string: "https://\(instance)\(item.url)")
        }
        return url
    }
    
    static func extractUUID(from id: String) -> String {
        if let url = URL(string: id), url.pathComponents.count >= 3 {
            return url.pathComponents.last ?? id
        }
        return id
    }
}

