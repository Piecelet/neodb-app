//
//  MastodonMention.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

struct MastodonMention: Codable {
  let id: String
  let username: String
  let url: URL
  let acct: String
}
