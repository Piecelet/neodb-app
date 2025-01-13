//
//  MastodonEmoji.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

struct MastodonEmoji: Codable, Hashable, Identifiable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(shortcode)
  }
  
  public var id: String {
    shortcode
  }
  
  public let shortcode: String
  public let url: URL
  public let staticUrl: URL
  public let visibleInPicker: Bool
}
