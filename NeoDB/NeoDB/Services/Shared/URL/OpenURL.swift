//
//  OpenURL.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog

class URLHandler {
    private static let logger = Logger.services.url.urlHandler

    static func handleItemURL(
        _ url: URL, completion: @escaping (RouterDestination?) -> Void
    ) {
        logger.debug("Handling URL: \(url.absoluteString)")
        
        if let destinationItem = NeoDBURL.parseItemURL(url) {
            completion(.itemDetailWithItem(item: destinationItem))
        } else {
            completion(nil)
        }
    }
}
