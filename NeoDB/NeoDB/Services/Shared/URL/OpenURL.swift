//
//  OpenURL.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation
import OSLog

class URLHandler {
    private static let logger = Logger.services.urlHandler

    static func handleItemURL(
        _ url: URL, completion: @escaping (RouterDestination?) -> Void
    ) {
        logger.debug("Handling URL: \(url.absoluteString)")
        
        if let destination = NeoDBURL.parseItemURL(url) {
            completion(destination)
        } else {
            completion(nil)
        }
    }
}
