//
//  JoinMastodonServers.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

struct JoinMastodonServers: Decodable, Hashable, Identifiable, Sendable {
    let domain, version, description: String
    let languages: [String]
    let region: Region
    let categories: [Category]
    let proxiedThumbnail: URL
    let blurhash: String?
    let totalUsers, lastWeekUsers: Int
    let approvalRequired: Bool
    let language: String
    let category: Category

    var id: String {
        domain
    }

    enum Category: String, Codable {
        case academia
        case activism
        case art
        case books
        case food
        case furry
        case games
        case general
        case hobby
        case journalism
        case lgbt
        case music
        case regional
        case religion
        case sports
        case tech
    }

    enum Region: String, Codable {
        case africa
        case asia
        case empty = ""
        case europe
        case northAmerica = "north_america"
        case oceania
        case southAmerica = "south_america"
    }
}
