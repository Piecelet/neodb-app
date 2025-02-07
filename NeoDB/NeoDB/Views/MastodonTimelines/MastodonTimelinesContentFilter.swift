//
//  MastodonTimelinesContentFilter.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import SwiftUI
import Perception

@MainActor
@Perceptible
class MastodonTimelinesContentFilter: ObservableObject {
    class Storage {
        @AppStorage("timeline_show_boosts") var showBoosts: Bool = true
        @AppStorage("timeline_show_replies") var showReplies: Bool = true
        @AppStorage("timeline_show_threads") var showThreads: Bool = true
        @AppStorage("timeline_quote_posts") var showQuotePosts: Bool = true
    }

    static let shared = MastodonTimelinesContentFilter()
    private let storage = Storage()

    var showBoosts: Bool {
        didSet {
            storage.showBoosts = showBoosts
        }
    }

    var showReplies: Bool {
        didSet {
            storage.showReplies = showReplies
        }
    }

    var showThreads: Bool {
        didSet {
            storage.showThreads = showThreads
        }
    }   
    
    var showQuotePosts: Bool {
        didSet {
            storage.showQuotePosts = showQuotePosts
        }
    }
    
    private init() {
        self.showBoosts = storage.showBoosts
        self.showReplies = storage.showReplies
        self.showThreads = storage.showThreads
        self.showQuotePosts = storage.showQuotePosts
    }
}