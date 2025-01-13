//
//  AppRegistrationResponse.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

struct AppRegistrationResponse: Codable {
    let clientId: String
    let clientSecret: String
    let name: String
    let redirectUri: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case name
        case redirectUri = "redirect_uri"
    }
}
