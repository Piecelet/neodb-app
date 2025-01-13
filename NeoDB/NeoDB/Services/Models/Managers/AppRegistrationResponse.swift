//
//  AppRegistrationResponse.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

struct AppClientResponse: Codable, Identifiable {
    let id: String
    let name: String
    let website: String?
    let redirectUri: String
    let clientId: String
    let clientSecret: String
    let vapidKey: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, website
        case redirectUri = "redirect_uri"
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case vapidKey = "vapid_key"
    }
} 