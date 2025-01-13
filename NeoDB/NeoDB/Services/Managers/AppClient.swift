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
    
    var key: String {
        let key = instance.lowercased()
        Self.logger.debug("Generated key for client: \(key)")
        return key
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        
        if !Self.keychain.set(data, forKey: key) {
            Self.logger.error("Failed to save client for instance: \(instance)")
            throw AccountError.keyChainError("Failed to save client")
        }
        Self.logger.debug("Saved client for instance: \(instance)")
    }
    
    func delete() {
        Self.keychain.delete(key)
        Self.logger.debug("Deleted client for instance: \(instance)")
    }
    
    static func retrieve(for instance: String) throws -> AppClient? {
        let key = KeychainKeys.client(instance).key
        guard let data = keychain.getData(key) else {
            return nil
        }
        
        do {
            let client = try JSONDecoder().decode(AppClient.self, from: data)
            logger.debug("Retrieved client for instance: \(instance)")
            return client
        } catch {
            logger.error("Failed to decode client data: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    static func get(for instance: String) async throws -> AppClient {
        // Try to retrieve existing client
        if let client = try? retrieve(for: instance) {
            logger.debug("Using existing client for instance: \(instance)")
            return client
        }
        
        // Register new client if none exists
        logger.debug("No existing client found, registering new one for instance: \(instance)")
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
            logger.debug("Registered and saved new client for instance: \(instance)")
            return client
            
        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                throw AccountError.invalidURL
            case .invalidResponse:
                throw AccountError.invalidResponse
            case .httpError(let code):
                throw AccountError.registrationFailed("HTTP error: \(code)")
            case .decodingError(let decodingError):
                throw AccountError.registrationFailed("Failed to decode response: \(decodingError.localizedDescription)")
            case .networkError(let networkError):
                throw AccountError.registrationFailed("Network error: \(networkError.localizedDescription)")
            case .unauthorized:
                throw AccountError.registrationFailed("Unauthorized")
            }
        }
    }
    
    static func retrieveAll() throws -> [AppClient] {
        let basePrefix = KeychainPrefixes.client
        let keys = keychain.allKeys
        
        logger.debug("Keychain access group: \(keychain.accessGroup ?? "nil")")
        logger.debug("All keychain keys: \(keys)")
        
        let filteredKeys = keys.filter { $0.hasPrefix(basePrefix) }
        var clients: [AppClient] = []
        
        logger.debug("Retrieving all clients with base prefix: \(basePrefix)")
        logger.debug("Found \(keys.count) total keys, \(filteredKeys.count) matching prefix")
        
        for key in filteredKeys {
            logger.debug("Processing key: \(key)")
            if let data = keychain.getData(key) {
                if let jsonString = String(data: data, encoding: .utf8) {
                    logger.debug("Retrieved data for key \(key): \(jsonString)")
                }
                
                do {
                    let client = try JSONDecoder().decode(AppClient.self, from: data)
                    clients.append(client)
                    logger.debug("Successfully decoded client for key: \(key), instance: \(client.instance)")
                } catch {
                    logger.error("Failed to decode client data for key: \(key), error: \(error.localizedDescription)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        logger.error("Failed to decode JSON: \(jsonString)")
                    }
                    throw error
                }
            } else {
                logger.error("No data found for key: \(key)")
            }
        }

        logger.debug("Retrieved \(clients.count) client(s) from \(filteredKeys.count) keys")
        return clients
    }
}
