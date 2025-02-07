//
//  MastodonTimelinesStatusFetching.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

protocol MastodonTimelinesStatusFetching: Sendable {
    func fetchFirstPage(
        accountsManager: AppAccountsManager?,
        timeline: MastodonTimelinesFilter
    ) async throws -> [MastodonStatus]
    func fetchNewPages(
        accountsManager: AppAccountsManager?,
        timeline: MastodonTimelinesFilter,
        minId: String,
        maxPages: Int
    ) async throws -> [MastodonStatus]
    func fetchNextPage(
        accountsManager: AppAccountsManager?,
        timeline: MastodonTimelinesFilter,
        lastId: String,
        offset: Int
    ) async throws -> [MastodonStatus]
}

enum StatusFetcherError: Error {
    case noClientAvailable
}

struct MastodonTimelinesStatusFetcher: MastodonTimelinesStatusFetching {
    func fetchFirstPage(
        accountsManager: AppAccountsManager?, timeline: MastodonTimelinesFilter
    ) async throws -> [MastodonStatus] {
        guard
            let client: NetworkClient = await accountsManager?.currentClient
        else { throw StatusFetcherError.noClientAvailable }
        return try await client.fetch(
            timeline.endpoint(
                sinceId: nil,
                maxId: nil,
                minId: nil,
                offset: 0,
                limit: 40), type: [MastodonStatus].self)
    }

    func fetchNewPages(
        accountsManager: AppAccountsManager?, timeline: MastodonTimelinesFilter,
        minId: String, maxPages: Int
    )
        async throws -> [MastodonStatus]
    {
        guard let client = await accountsManager?.currentClient else {
            throw StatusFetcherError.noClientAvailable
        }
        var allStatuses: [MastodonStatus] = []
        var latestMinId = minId
        for _ in 1...maxPages {
            if Task.isCancelled { break }

            let newStatuses: [MastodonStatus] = try await client.fetch(
                timeline.endpoint(
                    sinceId: nil,
                    maxId: nil,
                    minId: latestMinId,
                    offset: nil,
                    limit: 40
                ), type: [MastodonStatus].self)

            if newStatuses.isEmpty { break }

            allStatuses.insert(contentsOf: newStatuses, at: 0)
            latestMinId = newStatuses.first?.id ?? latestMinId
        }
        return allStatuses
    }

    func fetchNextPage(
        accountsManager: AppAccountsManager?, timeline: MastodonTimelinesFilter,
        lastId: String, offset: Int
    )
        async throws -> [MastodonStatus]
    {
        guard let client = await accountsManager?.currentClient else {
            throw StatusFetcherError.noClientAvailable
        }
        return try await client.fetch(
            timeline.endpoint(
                sinceId: nil,
                maxId: lastId,
                minId: nil,
                offset: offset,
                limit: 40), type: [MastodonStatus].self)
    }
}
