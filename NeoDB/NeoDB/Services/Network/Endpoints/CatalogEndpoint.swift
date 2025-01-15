//
//  CatalogEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum CatalogEndpoint {
    case search(query: String, category: ItemCategory? = nil, page: Int? = nil)
    case fetch(url: URL)
    case gallery
}

extension CatalogEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .search:
            return "/catalog/search"
        case .fetch:
            return "/catalog/fetch"
        case .gallery:
            return "/catalog/gallery"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .search(let query, let category, let page):
            var items: [URLQueryItem] = [
                .init(name: "query", value: query),
            ]
            
            if let category = category {
                items.append(.init(name: "category", value: category.rawValue))
            }
            
            if let page = page {
                items.append(.init(name: "page", value: page.description))
            }
            
            return items
        case .fetch(let url):
            return [
                .init(name: "url", value: url.absoluteString)
            ]
        case .gallery:
            return nil
        }
    }
}

