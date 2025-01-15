//
//  MastodonCard.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

public struct MastodonCard: Codable, Identifiable {
  public var id: String {
    url.absoluteString
  }
  
  public let url: URL
  public let title: String?
  public let description: String?
  public let type: String
  public let image: URL?
}
