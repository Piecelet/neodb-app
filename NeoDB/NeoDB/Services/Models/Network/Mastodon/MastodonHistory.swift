//
//  MastodonHistory.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

public struct MastodonHistory: Codable, Identifiable, Sendable, Equatable, Hashable {
  public var id: String {
    day
  }

  public let day: String
  public let accounts: String
  public let uses: String
}
