//
//  MastodonStatusesFetcher.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

@MainActor
protocol MastodonStatusesFetcher {
  var statusesState: MastodonStatusesState { get }
  func fetchNewestStatuses(pullToRefresh: Bool) async
  func fetchNextPage() async throws
  func statusDidAppear(status: MastodonStatus)
  func statusDidDisappear(status: MastodonStatus)
}
