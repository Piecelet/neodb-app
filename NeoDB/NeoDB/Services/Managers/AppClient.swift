//
//  AppClient.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation
import KeychainSwift
import OSLog

struct AppClient: Codable, Identifiable {
    private static let logger = Logger.managers.client
    private static let keychain = KeychainSwift(keyPrefix: KeychainPrefixes.client)
    
    let id: String
    let name: String
    let website: URL?
    let redirectUri: String
    let clientId: String
    let clientSecret: String
    let vapidKey: String
    let instance: String
    
    private static func cleanInstanceHost(from instance: String) -> String {
        if let components = URLComponents(string: instance),
           let host = components.host {
            return host
        } else if let components = URLComponents(string: "https://\(instance)"),
                  let host = components.host {
            return host
        }
        return instance.lowercased()
    }
    
    var key: String {
        let key = Self.cleanInstanceHost(from: instance)
        Self.logger.debug("Generated key for client")
        return key
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        
        if !Self.keychain.set(data, forKey: key) {
            Self.logger.error("Failed to save client")
            throw AccountError.keyChainError("Failed to save client")
        }
        Self.logger.debug("Saved client")
    }
    
    func delete() {
        Self.keychain.delete(key)
        Self.logger.debug("Deleted client")
    }
    
    static func retrieve(for instance: String) throws -> AppClient? {
        let key = cleanInstanceHost(from: instance)
        guard let data = keychain.getData(key) else {
            return nil
        }
        
        do {
            let client = try JSONDecoder().decode(AppClient.self, from: data)
            logger.debug("Retrieved client")
            return client
        } catch {
            logger.error("Failed to decode client data")
            throw error
        }
    }
    
    @MainActor
    static func get(for instance: String) async throws -> AppClient {
        // Try to retrieve existing client
        if let client = try? retrieve(for: instance) {
            logger.debug("Using existing client")
            return client
        }
        
        // Register new client if none exists
        logger.debug("No existing client found, registering new one")
        return try await register(for: instance)
    }
    
    @MainActor
    private static func register(for instance: String) async throws -> AppClient {
        let networkClient = NetworkClient(instance: instance)
        let endpoint = AppsEndpoint.create
        
        do {
            let response = try await networkClient.fetch(endpoint, type: AppsResponse.self)
            let client = AppClient(
                id: response.id,
                name: response.name,
                website: response.website,
                redirectUri: response.redirectUri,
                clientId: response.clientId,
                clientSecret: response.clientSecret,
                vapidKey: response.vapidKey,
                instance: instance
            )
            
            try client.save()
            logger.debug("Registered and saved new client")
            return client
            
        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                throw AccountError.invalidURL
            case .invalidResponse:
                throw AccountError.invalidResponse
            case .httpError(let code):
                throw AccountError.registrationFailed("HTTP error: \(code)")
            case .decodingError:
                throw AccountError.registrationFailed("Failed to decode response")
            case .networkError:
                throw AccountError.registrationFailed("Network error")
            case .unauthorized:
                throw AccountError.registrationFailed("Unauthorized")
            }
        }
    }
}
