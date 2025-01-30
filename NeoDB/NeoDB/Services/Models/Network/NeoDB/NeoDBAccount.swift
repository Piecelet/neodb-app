//
//  NeoDBAccount.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/30/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct NeoDBAccount: Codable, Identifiable, Hashable, Sendable, Equatable {
    let id: String
    let username: String
    let acct: String
    let url: String
    let displayName: String
    let note: String
    let avatar: String
    let avatarStatic: String
    let header: String?
    let headerStatic: String?
    let locked: Bool
    let fields: [NeoDBAccountField]
    let emojis: [NeoDBEmoji]
    let bot: Bool
    let group: Bool
    let discoverable: Bool
    let indexable: Bool
    let moved: MovedValue?
    let suspended: Bool?
    let limited: Bool?
    let createdAt: String
    let source: Source?

    var idHash: Int {
        id.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NeoDBAccount, rhs: NeoDBAccount) -> Bool {
        return lhs.id == rhs.id
    }

    enum Source: Codable, Hashable, Sendable, Equatable {
        case unknown
    }
}


// MARK: - Inner Enums
indirect enum MovedValue: Hashable, Sendable {
    case bool(Bool)
    case account(NeoDBAccount)
    case none
}

extension MovedValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .none
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let accountValue = try? container.decode(NeoDBAccount.self) {
            self = .account(accountValue)
        } else {
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encodeNil()
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .account(let accountValue):
            try container.encode(accountValue)
        }
    }
}
