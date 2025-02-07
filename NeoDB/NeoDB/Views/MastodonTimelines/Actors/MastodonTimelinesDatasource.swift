//
//  TimelinesDatasource.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

actor MastodonTimelinesDatasource {
    private var statuses: [MastodonStatus] = []

    var isEmpty: Bool {
        statuses.isEmpty
    }

    func get() -> [MastodonStatus] {
        statuses
    }

    func getFiltered() async -> [MastodonStatus] {
        let contentFilter = await MastodonTimelinesContentFilter.shared
        let showReplies = await contentFilter.showReplies
        let showThreads = await contentFilter.showThreads
        let showQuotePosts = await contentFilter.showQuotePosts
        let showBoosts = await contentFilter.showBoosts

        return statuses.filter { status in
            if status.isHidden
                || !showReplies && status.inReplyToId != nil
                    && status.inReplyToAccountId != status.account.id
                || !showBoosts && status.reblog != nil
                || !showThreads
                    && status.inReplyToAccountId == status.account.id
                || !showQuotePosts && !status.content.statusesURLs.isEmpty
            {
                return false
            }
            return true
        }

    }

    func count() -> Int {
        statuses.count
    }

    func reset() {
        statuses = []
    }

    func indexOf(statusId: String) -> Int? {
        statuses.firstIndex { $0.id == statusId }
    }

    func contains(statusId: String) -> Bool {
        statuses.contains { $0.id == statusId }
    }

    func set(_ statuses: [MastodonStatus]) {
        self.statuses = statuses
    }

    func append(_ status: MastodonStatus) {
        statuses.append(status)
    }

    func append(contentOf: [MastodonStatus]) {
        statuses.append(contentsOf: contentOf)
    }

    func insert(_ status: MastodonStatus, at: Int) {
        statuses.insert(status, at: at)
    }

    func insert(contentOf: [MastodonStatus], at: Int) {
        statuses.insert(contentsOf: contentOf, at: at)
    }

    func remove(after: MastodonStatus, safeOffset: Int) {
        if let index = statuses.firstIndex(of: after) {
            let safeIndex = index + safeOffset
            if statuses.count > safeIndex {
                statuses.removeSubrange(safeIndex..<statuses.endIndex)
            }
        }
    }

    func replace(_ status: MastodonStatus, at: Int) {
        statuses[at] = status
    }

    func remove(_ statusId: String) -> MastodonStatus? {
        if let index = statuses.firstIndex(where: { status in
            status.id == statusId
        }) {
            return statuses.remove(at: index)
        }
        return nil
    }
}
