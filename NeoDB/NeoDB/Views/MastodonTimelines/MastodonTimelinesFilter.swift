//
//  TimelinesFilter.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import SwiftUI

enum MastodonTimelinesFilter: String, Hashable, Equatable, Identifiable, Sendable, CaseIterable {
    case following, local, trending, federated
    case latest
    case resume

    var id: String {
        return self.title
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func availableTimeline(isAuthenticated: Bool = false) -> [MastodonTimelinesFilter] {
        if !isAuthenticated {
            return [.local, .trending, .federated]
        }
        return [.following, .local, .trending, .federated]
    }

    var supportNewestPagination: Bool {
        switch self {
        case .trending:
            return true
        default:
            return true
        }
    }

    var title: String {
        switch self {
        case .following:
            "Following"
        case .local:
            "Local"
        case .trending:
            "Trending"
        case .federated:
            "Federated"
        case .latest:
            "Latest"
        case .resume:
            "Resume"
        }
    }

    var displayName: String {
        switch self {
        case .following:
            String(localized: "timelines_type_following", defaultValue: "Following", table: "Timelines")
        case .local:
            String(localized: "timelines_type_local", defaultValue: "Local", table: "Timelines")
        case .trending:
            String(localized: "timelines_type_trending", defaultValue: "Trending", table: "Timelines")
        case .federated:
            String(localized: "timelines_type_federated", defaultValue: "Federated", table: "Timelines")
        case .latest:
            String(localized: "timelines_type_latest", defaultValue: "Latest", table: "Timelines")
        case .resume:
            String(localized: "timelines_type_resume", defaultValue: "Resume", table: "Timelines")
        }
    }
    

    func endpoint(sinceId: String? = nil, maxId: String? = nil, minId: String? = nil, offset: Int? = nil, limit: Int? = nil) -> TimelinesEndpoint {
        switch self {
        case .following:
            return .home(sinceId: sinceId, maxId: maxId, minId: minId, limit: limit)
        case .local:
            return .pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true, limit: limit)
        case .trending:
            return .trending(maxId: maxId)
        case .federated:
            return .pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false, limit: limit)
        case .latest: return .home(sinceId: nil, maxId: nil, minId: nil, limit: limit)
        case .resume: return .home(sinceId: nil, maxId: nil, minId: nil, limit: limit)
        }
    }
}
