//
//  MarkDataControllerProvider.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

@MainActor
protocol MarkDataControlling {
    func updateMark(uuid: String, mark: MarkInSchema) async throws
}

@MainActor
final class MarkDataControllerProvider: MarkDataControlling {
    public static let shared = MarkDataControllerProvider()

    private var cache: NSMutableDictionary = [:]

    func dataController(for MarkSchema) -> MarkDataController {
        let key = CacheKey(uuid: uuid)
        if let controller = cache[key] as? MarkDataController {
            return controller
        }
        let controller = MarkDataController(uuid: uuid)
        cache[key] = controller
    }
    
    func updateMark(uuid: String, mark: MarkInSchema) async throws {
        let endpoint = MarkEndpoint.mark(itemId: uuid, mark: mark)
        let mark = try await accountsManager.currentClient.fetch(endpoint, type: MarkSchema.self)
    }
}