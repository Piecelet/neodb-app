//
//  MastodonStatusesState.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

enum MastodonStatusesState {
  enum PagingState {
    case hasNextPage, none
  }

  case loading
  case display(statuses: [MastodonStatus], nextPageState: MastodonStatusesState.PagingState)
  case error(error: Error)
}