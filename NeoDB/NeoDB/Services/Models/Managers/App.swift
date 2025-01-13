//
//  App.swift
//  NeoDB
//
//  Created by citron on 1/12/25.
//

import Foundation
import OSLog

enum AccountError: Error {
    case notAuthenticated
    case invalidInstance
    case invalidURL
    case invalidResponse
    case registrationFailed(String)
    case authenticationFailed(String)
    case tokenRefreshFailed(String)
    case keyChainError(String)
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidInstance:
            return "Invalid instance URL"
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid server response"
        case .registrationFailed(let message):
            return "App registration failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .keyChainError(let message):
            return "Keychain operation failed: \(message)"
        }
    }
}
