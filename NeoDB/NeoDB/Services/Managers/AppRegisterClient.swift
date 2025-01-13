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
    private let redirectUri = "neodb://oauth/callback"
    
    func registerApp(instance: String) async throws -> InstanceClient {
        // Check existing client credentials
        if let client = getInstanceClient(for: instance) {
            logger.debug("Using existing client credentials for instance: \(instance)")
            return client
        }
        
        // Build registration request
        guard let url = URL(string: "https://\(instance)/api/v1/apps") else {
            throw AccountError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_name": "NeoDB iOS App",
            "redirect_uris": redirectUri,
            "website": "https://github.com/citron/neodb-app"
        ]
        
        let body = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        // Send registration request
        logger.debug("Registering app with instance: \(instance)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AccountError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                logger.error("Registration failed for instance \(instance): \(errorMessage)")
                throw AccountError.registrationFailed(errorMessage)
            }
            throw AccountError.registrationFailed("Registration failed with status code: \(httpResponse.statusCode)")
        }
        
        // Parse response
        let registrationResponse = try JSONDecoder().decode(AppRegistrationResponse.self, from: data)
        
        // Create and save client credentials
        let client = InstanceClient(
            clientId: registrationResponse.clientId,
            clientSecret: registrationResponse.clientSecret,
            instance: instance
        )
        
        if !saveInstanceClient(client) {
            throw AccountError.keyChainError("Failed to save client credentials")
        }
        
        logger.debug("App registered successfully with client_id: \(registrationResponse.clientId) for instance: \(instance)")
        return client
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
