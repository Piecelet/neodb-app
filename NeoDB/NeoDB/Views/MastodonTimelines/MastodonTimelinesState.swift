//
//  MastodonTimelinesState.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct MastodonTimelinesState: Equatable {
    var statuses: [MastodonStatus] = []
    var isInited = false
    var isLoading = false {
        didSet {
            if isLoading {
                error = nil
            }
        }
    }
    var isRefreshing = false {
        didSet {
            if isRefreshing {
                error = nil
            }
        }
    }
    var error: Error?
    
    // Pagination
    var maxId: String?
    var hasMore = true
    
    // Stream management
    var isActive = false
    var lastRefreshTime: Date?
    
    static func == (lhs: MastodonTimelinesState, rhs: MastodonTimelinesState) -> Bool {
        lhs.statuses.map(\.id) == rhs.statuses.map(\.id) &&
        lhs.isLoading == rhs.isLoading &&
        lhs.isRefreshing == rhs.isRefreshing &&
        lhs.maxId == rhs.maxId &&
        lhs.hasMore == rhs.hasMore &&
        lhs.isActive == rhs.isActive &&
        lhs.lastRefreshTime == rhs.lastRefreshTime
    }
}

