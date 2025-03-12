//
//  MastodonAccountRelationship.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 3/12/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct MastodonAccountRelationship: Codable, Equatable, Identifiable {
  let id: String
  let following: Bool
  let showingReblogs: Bool
  let followedBy: Bool
  let blocking: Bool
  let blockedBy: Bool
  let muting: Bool
  let mutingNotifications: Bool
  let requested: Bool
  let domainBlocking: Bool
  let endorsed: Bool
  let note: String
  let notifying: Bool

  static func placeholder() -> MastodonAccountRelationship {
    .init(
      id: UUID().uuidString,
      following: false,
      showingReblogs: false,
      followedBy: false,
      blocking: false,
      blockedBy: false,
      muting: false,
      mutingNotifications: false,
      requested: false,
      domainBlocking: false,
      endorsed: false,
      note: "",
      notifying: false)
  }
}

extension MastodonAccountRelationship {
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
    following = try values.decodeIfPresent(Bool.self, forKey: .following) ?? false
    showingReblogs = try values.decodeIfPresent(Bool.self, forKey: .showingReblogs) ?? false
    followedBy = try values.decodeIfPresent(Bool.self, forKey: .followedBy) ?? false
    blocking = try values.decodeIfPresent(Bool.self, forKey: .blocking) ?? false
    blockedBy = try values.decodeIfPresent(Bool.self, forKey: .blockedBy) ?? false
    muting = try values.decodeIfPresent(Bool.self, forKey: .muting) ?? false
    mutingNotifications =
      try values.decodeIfPresent(Bool.self, forKey: .mutingNotifications) ?? false
    requested = try values.decodeIfPresent(Bool.self, forKey: .requested) ?? false
    domainBlocking = try values.decodeIfPresent(Bool.self, forKey: .domainBlocking) ?? false
    endorsed = try values.decodeIfPresent(Bool.self, forKey: .endorsed) ?? false
    note = try values.decodeIfPresent(String.self, forKey: .note) ?? ""
    notifying = try values.decodeIfPresent(Bool.self, forKey: .notifying) ?? false
  }
}

extension MastodonAccountRelationship: Sendable {}
