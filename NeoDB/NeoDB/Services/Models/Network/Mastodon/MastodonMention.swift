//
//  MastodonMention.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//
//  From https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
//

import Foundation

struct MastodonMention: Codable, Equatable, Hashable {
  let id: String
  let username: String
  let url: URL
  let acct: String
}

extension MastodonMention: Sendable {}
