// 
//  AuthService.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Foundation
import SwiftUI
import OSLog
import KeychainSwift

enum AuthError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case registrationFailed(String)
    case tokenExchangeFailed(String)
    case invalidInstance
    case noClientCredentials
}

struct AppRegistrationResponse: Codable {
    let client_id: String
    let client_secret: String
    let name: String
    let redirect_uri: String
}

struct InstanceClient: Codable {
    let clientId: String
    let clientSecret: String
    let instance: String
}

@MainActor
class AuthService: ObservableObject {
    private let logger = Logger.auth
    private let keychain: KeychainSwift
    
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var isRegistering = false
    @Published var currentInstance: String {
        didSet {
            let lowercaseInstance = self.currentInstance.lowercased()
            if lowercaseInstance != self.currentInstance {
                self.currentInstance = lowercaseInstance
                return
            }
            // Save the current instance
            UserDefaults.standard.set(self.currentInstance, forKey: "neodb.currentInstance")
            logger.debug("Switched to instance: \(self.currentInstance)")
        }
    }
    
    private var baseURL: String { "https://\(self.currentInstance)" }
    private let redirectUri = "neodb://oauth/callback"
    private let scopes = "read write"
    
    init(instance: String? = nil) {
        // Load last used instance or use default, ensure it's lowercase
        self.currentInstance = (instance ?? UserDefaults.standard.string(forKey: "neodb.currentInstance") ?? "neodb.social").lowercased()
        self.keychain = KeychainSwift(keyPrefix: "neodb_")
        
        logger.debug("Initialized with instance: \(self.currentInstance)")
        
        // Check if we have a saved access token for current instance
        if let token = savedAccessToken {
            accessToken = token
            isAuthenticated = true
            logger.debug("Found saved access token for instance: \(self.currentInstance)")
        }
        
        // Log if we have client credentials
        if let client = getInstanceClient(for: self.currentInstance) {
            logger.debug("Found existing client credentials for instance: \(self.currentInstance), client_id: \(client.clientId)")
        }
    }
    
    private var clientId: String? {
        get { 
            guard let clientData = getInstanceClient(for: self.currentInstance) else { 
                logger.debug("No client_id found for instance: \(self.currentInstance)")
                return nil 
            }
            return clientData.clientId
        }
        set {
            if let value = newValue, let secretValue = clientSecret {
                saveInstanceClient(InstanceClient(
                    clientId: value,
                    clientSecret: secretValue,
                    instance: self.currentInstance
                ))
                logger.debug("Saved client_id for instance: \(self.currentInstance)")
            }
        }
    }
    
    private var clientSecret: String? {
        get {
            guard let clientData = getInstanceClient(for: self.currentInstance) else { 
                logger.debug("No client_secret found for instance: \(self.currentInstance)")
                return nil 
            }
            return clientData.clientSecret
        }
        set {
            if let value = newValue, let idValue = clientId {
                saveInstanceClient(InstanceClient(
                    clientId: idValue,
                    clientSecret: value,
                    instance: self.currentInstance
                ))
                logger.debug("Saved client_secret for instance: \(self.currentInstance)")
            }
        }
    }
    
    private var savedAccessToken: String? {
        get { keychain.get("access_token_\(self.currentInstance)") }
        set {
            if let value = newValue {
                keychain.set(value, forKey: "access_token_\(self.currentInstance)")
                accessToken = value
                isAuthenticated = true
                logger.debug("Saved access token for instance: \(self.currentInstance)")
            } else {
                keychain.delete("access_token_\(self.currentInstance)")
                accessToken = nil
                isAuthenticated = false
                logger.debug("Removed access token for instance: \(self.currentInstance)")
            }
        }
    }
    
    private func getInstanceClient(for instance: String) -> InstanceClient? {
        guard let data = keychain.getData("client_\(instance)"),
              let client = try? JSONDecoder().decode(InstanceClient.self, from: data)
        else { 
            logger.debug("Failed to get client data for instance: \(instance)")
            return nil 
        }
        logger.debug("Retrieved client data for instance: \(instance)")
        return client
    }
    
    private func saveInstanceClient(_ client: InstanceClient) {
        if let data = try? JSONEncoder().encode(client) {
            keychain.set(data, forKey: "client_\(client.instance)")
            logger.debug("Saved client data for instance: \(client.instance)")
        } else {
            logger.error("Failed to encode client data for instance: \(client.instance)")
        }
    }
    
    private func removeInstanceClient(for instance: String) {
        keychain.delete("client_\(instance)")
        logger.debug("Removed client data for instance: \(instance)")
    }
    
    func validateInstance(_ instance: String) -> Bool {
        let lowercaseInstance = instance.lowercased()
        // Basic validation: ensure it's a valid hostname
        let hostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
        let hostnamePredicate = NSPredicate(format: "SELF MATCHES %@", hostnameRegex)
        return hostnamePredicate.evaluate(with: lowercaseInstance)
    }
    
    func switchInstance(_ newInstance: String) throws {
        let lowercaseInstance = newInstance.lowercased()
        guard validateInstance(lowercaseInstance) else {
            throw AuthError.invalidInstance
        }
        
        logger.debug("Switching from instance \(self.currentInstance) to \(lowercaseInstance)")
        
        // Logout from current instance but keep the client credentials
        logout()
        
        // Switch to new instance
        currentInstance = lowercaseInstance
        
        // Clear current session but keep client credentials
        savedAccessToken = nil
        isAuthenticated = false
    }
    
    var authorizationURL: URL? {
        guard let clientId = clientId else { 
            logger.error("Cannot create authorization URL: no client_id available")
            return nil 
        }
        var components = URLComponents(string: "\(baseURL)/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes),
            // Add current instance as state to restore it after callback
            URLQueryItem(name: "state", value: self.currentInstance)
        ]
        logger.debug("Created authorization URL for instance: \(self.currentInstance)")
        return components?.url
    }
    
    func registerApp() async throws {
        // Check if we already have valid credentials for this instance
        if let client = getInstanceClient(for: self.currentInstance) {
            logger.debug("Using existing client credentials for instance: \(self.currentInstance), client_id: \(client.clientId)")
            return
        }
        
        isRegistering = true
        defer { isRegistering = false }
        
        guard let url = URL(string: "\(baseURL)/api/v1/apps") else {
            throw AuthError.invalidURL
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
        
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        logger.debug("Registering app with instance: \(self.currentInstance)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                logger.error("Registration failed for instance \(self.currentInstance): \(errorMessage)")
                throw AuthError.registrationFailed(errorMessage)
            }
            throw AuthError.registrationFailed("Registration failed with status code: \(httpResponse.statusCode)")
        }
        
        let registrationResponse = try JSONDecoder().decode(AppRegistrationResponse.self, from: data)
        
        // Save the client credentials for this instance
        let client = InstanceClient(
            clientId: registrationResponse.client_id,
            clientSecret: registrationResponse.client_secret,
            instance: currentInstance
        )
        saveInstanceClient(client)
        
        logger.debug("App registered successfully with client_id: \(registrationResponse.client_id) for instance: \(self.currentInstance)")
    }
    
    func handleCallback(url: URL) async throws {
        logger.debug("Handling OAuth callback with URL: \(url)")
        
        // Extract instance from saved state if available
        if let state = URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "state" })?
            .value,
           !state.isEmpty && state != "None" {
            // If state contains instance information, use it
            currentInstance = state.lowercased()
            logger.debug("Restored instance from state: \(self.currentInstance)")
        }
        
        // Verify we have client credentials before proceeding
        guard let client = getInstanceClient(for: self.currentInstance) else {
            logger.error("No client credentials found for instance: \(self.currentInstance)")
            throw AuthError.noClientCredentials
        }
        logger.debug("Found client credentials for callback, client_id: \(client.clientId)")
        
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
        else {
            logger.error("No authorization code found in callback URL")
            throw AuthError.invalidResponse
        }
        
        logger.debug("Authorization code received: \(code) for instance: \(self.currentInstance)")
        try await exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) async throws {
        logger.debug("Exchanging authorization code for token")
        
        // Double check we're using the correct instance
        logger.debug("Exchanging token for instance: \(self.currentInstance)")
        
        guard let client = getInstanceClient(for: self.currentInstance) else {
            logger.error("No client credentials found for token exchange on instance: \(self.currentInstance)")
            throw AuthError.noClientCredentials
        }
        
        logger.debug("Using client_id: \(client.clientId) for token exchange on instance: \(self.currentInstance)")
        
        guard let url = URL(string: "\(baseURL)/oauth/token") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": client.clientId,
            "client_secret": client.clientSecret,
            "code": code,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]
        
        let body = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                logger.error("Token exchange failed for instance \(self.currentInstance): \(errorMessage), status code: \(httpResponse.statusCode)")
                // If unauthorized, clear stored credentials for this instance
                if httpResponse.statusCode == 401 {
                    removeInstanceClient(for: self.currentInstance)
                    savedAccessToken = nil
                }
                throw AuthError.tokenExchangeFailed(errorMessage)
            }
            logger.error("Token exchange failed for instance \(self.currentInstance) with status code: \(httpResponse.statusCode)")
            throw AuthError.tokenExchangeFailed("Failed with status code: \(httpResponse.statusCode)")
        }
        
        struct TokenResponse: Codable {
            let access_token: String
            let token_type: String
            let scope: String
        }
        
        do {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            self.savedAccessToken = tokenResponse.access_token
            logger.debug("Successfully obtained access token for instance: \(self.currentInstance)")
        } catch {
            logger.error("Failed to decode token response for instance \(self.currentInstance): \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Raw response: \(responseString)")
            }
            throw error
        }
    }
    
    func logout() {
        logger.info("User logged out")
        savedAccessToken = nil
        isAuthenticated = false
        logger.debug("Logged out from instance: \(self.currentInstance)")
    }
    
    func clearAllData() {
        // Clear all keychain data
        keychain.clear()
        // Clear current instance
        UserDefaults.standard.removeObject(forKey: "neodb.currentInstance")
        // Reset state
        currentInstance = "neodb.social"
        isAuthenticated = false
        accessToken = nil
        logger.debug("Cleared all data")
    }
}

