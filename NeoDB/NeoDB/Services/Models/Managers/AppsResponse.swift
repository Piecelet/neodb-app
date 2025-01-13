//
//  AppRegistrationResponse.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

struct AppsResponse: Codable, Identifiable {
  let id: String
  let name: String
  let website: URL?
  let redirectUri: String
  let clientId: String
  let clientSecret: String
  let vapidKey: String
}
