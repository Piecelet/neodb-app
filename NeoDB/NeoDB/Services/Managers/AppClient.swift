//
//  AppRegisterClient.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation
import OSLog
import KeychainSwift


@MainActor
class AppRegisterClient {
    private let logger = Logger.networkAuth
    private let keychain = KeychainSwift(keyPrefix: "neodb_")
    
    func registerApp(instance: String) async throws -> InstanceClient {
        // Check existing client credentials
        if let client = getInstanceClient(for: instance) {
            logger.debug("Using existing client credentials for instance: \(instance)")
            return client
        }
        
        // Create network client for registration
        let networkClient = NetworkClient(instance: instance)
        let endpoint = AppsEndpoints.create
        
        do {
            // Send registration request
            logger.debug("Registering app with instance: \(instance)")
            let response = try await networkClient.fetch(endpoint, type: AppRegistrationResponse.self)
            
            // Create and save client credentials
            let client = InstanceClient(
                clientId: response.clientId,
                clientSecret: response.clientSecret,
                instance: instance
            )
            
            if !saveInstanceClient(client) {
                throw AccountError.keyChainError("Failed to save client credentials")
            }
            
            logger.debug("App registered successfully with client_id: \(response.clientId) for instance: \(instance)")
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
    
    private func getInstanceClient(for instance: String) -> InstanceClient? {
        guard let data = keychain.getData("client_\(instance)"),
              let client = try? JSONDecoder().decode(InstanceClient.self, from: data)
        else {
            logger.debug("No client credentials found for instance: \(instance)")
            return nil
        }
        logger.debug("Retrieved client credentials for instance: \(instance)")
        return client
    }
    
    private func saveInstanceClient(_ client: InstanceClient) -> Bool {
        guard let data = try? JSONEncoder().encode(client) else {
            logger.error("Failed to encode client credentials for instance: \(client.instance)")
            return false
        }
        
        let saved = keychain.set(data, forKey: "client_\(client.instance)")
        if saved {
            logger.debug("Saved client credentials for instance: \(client.instance)")
        } else {
            logger.error("Failed to save client credentials to keychain for instance: \(client.instance)")
        }
        return saved
    }
}
