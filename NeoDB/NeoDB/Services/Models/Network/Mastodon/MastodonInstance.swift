//
//  MastodonInstance.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

struct MastodonInstance: Codable, Sendable {
    struct Stats: Codable, Sendable {
        let userCount: Int
        let statusCount: Int
        let domainCount: Int
    }

    struct Configuration: Codable, Sendable {
        struct Statuses: Codable, Sendable {
            let maxCharacters: Int
            let maxMediaAttachments: Int
        }

        struct Polls: Codable, Sendable {
            let maxOptions: Int
            let maxCharactersPerOption: Int
            let minExpiration: Int
            let maxExpiration: Int
        }

        let statuses: Statuses
        let polls: Polls
    }

    struct Rule: Codable, Identifiable, Sendable {
        let id: String
        let text: HTMLString
    }

    struct URLs: Codable, Sendable {
        let streamingApi: URL?
    }

    let title: String
    let shortDescription: String
    let email: String
    let version: String
    let stats: Stats
    let languages: [String]?
    let registrations: Bool
    let thumbnail: URL?
    let configuration: Configuration?
    let rules: [Rule]?
    let urls: URLs?
}
