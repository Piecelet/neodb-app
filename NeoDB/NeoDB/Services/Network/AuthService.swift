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
}

struct AppRegistrationResponse: Codable {
    let client_id: String
    let client_secret: String
    let name: String
    let redirect_uri: String
}

@MainActor
class AuthService: ObservableObject {
    private let logger = Logger(subsystem: "com.neodb.app", category: "Auth")
    private let keychain = KeychainSwift(keyPrefix: "neodb_")
    
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var isRegistering = false
    
    private let baseURL = "https://neodb.social"
    private var clientId: String? {
        get { keychain.get("client_id") }
        set { 
            if let value = newValue {
                keychain.set(value, forKey: "client_id")
            } else {
                keychain.delete("client_id")
            }
        }
    }
    private var clientSecret: String? {
        get { keychain.get("client_secret") }
        set { 
            if let value = newValue {
                keychain.set(value, forKey: "client_secret")
            } else {
                keychain.delete("client_secret")
            }
        }
    }
    private var savedAccessToken: String? {
        get { keychain.get("access_token") }
        set {
            if let value = newValue {
                keychain.set(value, forKey: "access_token")
                accessToken = value
                isAuthenticated = true
            } else {
                keychain.delete("access_token")
                accessToken = nil
                isAuthenticated = false
            }
        }
    }
    
    private let redirectUri = "neodb://oauth/callback"
    private let scopes = "read write"
    
    init() {
        // Check if we have a saved access token
        if let token = savedAccessToken {
            accessToken = token
            isAuthenticated = true
        }
    }
    
    var authorizationURL: URL? {
        guard let clientId = clientId else { return nil }
        var components = URLComponents(string: "\(baseURL)/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes)
        ]
        return components?.url
    }
    
    func registerApp() async throws {
        // If we already have credentials, no need to register again
        if clientId != nil && clientSecret != nil {
            logger.debug("Using existing client credentials")
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                logger.error("Registration failed: \(errorMessage)")
                throw AuthError.registrationFailed(errorMessage)
            }
            throw AuthError.registrationFailed("Registration failed with status code: \(httpResponse.statusCode)")
        }
        
        let registrationResponse = try JSONDecoder().decode(AppRegistrationResponse.self, from: data)
        self.clientId = registrationResponse.client_id
        self.clientSecret = registrationResponse.client_secret
        logger.debug("App registered successfully with client_id: \(registrationResponse.client_id)")
    }
    
    func handleCallback(url: URL) async throws {
        logger.debug("Handling callback URL: \(url)")
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
        else {
            logger.error("No authorization code found in callback URL")
            throw AuthError.invalidResponse
        }
        
        logger.debug("Authorization code received: \(code)")
        try await exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) async throws {
        guard let clientId = clientId, let clientSecret = clientSecret else {
            logger.error("No client credentials found for token exchange")
            throw AuthError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/oauth/token") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
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
                logger.error("Token exchange failed: \(errorMessage), status code: \(httpResponse.statusCode)")
                // If unauthorized, clear stored credentials
                if httpResponse.statusCode == 401 {
                    self.clientId = nil
                    self.clientSecret = nil
                    self.savedAccessToken = nil
                }
                throw AuthError.tokenExchangeFailed(errorMessage)
            }
            logger.error("Token exchange failed with status code: \(httpResponse.statusCode)")
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
            logger.debug("Successfully obtained access token")
        } catch {
            logger.error("Failed to decode token response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Raw response: \(responseString)")
            }
            throw error
        }
    }
    
    func logout() {
        clientId = nil
        clientSecret = nil
        savedAccessToken = nil
    }
}