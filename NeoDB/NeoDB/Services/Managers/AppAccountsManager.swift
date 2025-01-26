//
//  AppAccountsManager.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import SwiftUI
import OSLog

@MainActor
class AppAccountsManager: ObservableObject {
    private let logger = Logger.managers.accountsManager
    private let redirectUri = AppConfig.OAuth.redirectUri
    private var oauthClient: AppClient?
    
    @AppStorage("latestCurrentAccountKey") static public
        var latestCurrentAccountKey: String = ""

    @AppStorage("hasShownPurchaseView") private var hasShownPurchaseView = false {
        didSet {
            logger.debug("hasShownPurchaseView changed to \(hasShownPurchaseView)")
        }
    }
    
    @Published var currentAccount: AppAccount {
        didSet {
            Self.latestCurrentAccountKey = currentAccount.id
            currentClient = NetworkClient(
                instance: currentAccount.instance,
                oauthToken: currentAccount.oauthToken
            )
        }
    }
    @Published var availableAccounts: [AppAccount]
    @Published var currentClient: NetworkClient
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var shouldShowPurchase = false {
        didSet {
            logger.debug("shouldShowPurchase changed to \(shouldShowPurchase)")
        }
    }

    init() {
        var defaultAccount = AppAccount(
            instance: AppConfig.defaultInstance, oauthToken: nil)
        do {
            let keychainAccounts = try AppAccount.retrieveAll()
            availableAccounts = keychainAccounts
            if let currentAccount = keychainAccounts.first(where: {
                $0.id == Self.latestCurrentAccountKey
            }) {
                defaultAccount = currentAccount
            } else {
                defaultAccount = keychainAccounts.last ?? defaultAccount
            }
        } catch {
            availableAccounts = [defaultAccount]
        }
        currentAccount = defaultAccount
        currentClient = NetworkClient(
            instance: defaultAccount.instance,
            oauthToken: defaultAccount.oauthToken
        )
        isAuthenticated = defaultAccount.oauthToken != nil
    }

    func add(account: AppAccount) {
        do {
            try account.save()
            availableAccounts.append(account)
            currentAccount = account
            isAuthenticated = account.oauthToken != nil
        } catch {
            logger.error("Failed to add account: \(error.localizedDescription)")
        }
    }

    func delete(account: AppAccount) {
        availableAccounts.removeAll(where: { $0.id == account.id })
        account.delete()
        if currentAccount.id == account.id {
            currentAccount =
                availableAccounts.first
                ?? AppAccount(instance: "neodb.social", oauthToken: nil)
            isAuthenticated = currentAccount.oauthToken != nil
        }
        
        // Reset hasShownPurchaseView when deleting the last account
            shouldShowPurchase = false
            hasShownPurchaseView = false
            logger.debug("Last account deleted, reset hasShownPurchaseView to false")
    }
    
    // MARK: - Authentication
    
    var authenticationUrl: URL? {
        guard let client = oauthClient else { return nil }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = currentAccount.instance
        components.path = "/oauth/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: client.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read write"),
            URLQueryItem(name: "state", value: currentAccount.instance)
        ]
        
        return components.url
    }
    
    func authenticate(instance: String) async throws -> URL {
        // Get app client (will register if needed)
        let client = try await AppClient.get(for: instance)
        oauthClient = client
        
        guard let url = authenticationUrl else {
            throw AccountError.invalidURL
        }
        
        logger.debug("Generated OAuth URL")
        return url
    }
    
    func handleCallback(url: URL, ignoreAuthenticationDuration: Bool = false) async throws {
        guard (isAuthenticating && ignoreAuthenticationDuration != true) else {
            logger.error("Received callback but not in authentication process")
            throw AccountError.authenticationFailed("Not in authentication process")
        }
        
        guard let client = oauthClient else {
            logger.error("No OAuth client available")
            throw AccountError.authenticationFailed("No OAuth client available")
        }
        
        // Extract instance from state
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            logger.error("Invalid callback URL")
            throw AccountError.invalidURL
        }
        
        do {
            let token = try await exchangeCodeForToken(
                code: code,
                client: client,
                instance: state
            )
            
            logger.debug("Authentication successful, hasShownPurchaseView: \(hasShownPurchaseView)")
            let account = AppAccount(instance: state, oauthToken: token)
            add(account: account)
            isAuthenticated = true
            logger.debug("After adding account, shouldShowPurchase: \(shouldShowPurchase)")
            if isAuthenticated, !hasShownPurchaseView {
                hasShownPurchaseView = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    shouldShowPurchase = true
                }
            } else {
                shouldShowPurchase = false
            }
        } catch {
            logger.error("Token exchange failed")
            throw error
        }
        
        isAuthenticating = false
        oauthClient = nil
    }
    
    private func exchangeCodeForToken(
        code: String,
        client: AppClient,
        instance: String
    ) async throws -> OauthToken {
        let networkClient = NetworkClient(instance: instance)
        let endpoint = OauthEndpoint.token(
            code: code,
            clientId: client.clientId,
            clientSecret: client.clientSecret,
            redirectUri: redirectUri
        )
        
        do {
            let token = try await networkClient.fetch(endpoint, type: OauthToken.self)
            logger.debug("Successfully exchanged code for token")
            return token
        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                throw AccountError.invalidURL
            case .invalidResponse:
                throw AccountError.invalidResponse
            case .httpError(let code):
                throw AccountError.tokenRefreshFailed("HTTP error: \(code)")
            case .decodingError:
                throw AccountError.tokenRefreshFailed("Failed to decode response")
            case .networkError:
                throw AccountError.tokenRefreshFailed("Network error")
            case .unauthorized:
                throw AccountError.tokenRefreshFailed("Unauthorized")
            case .cancelled:
                throw AccountError.tokenRefreshFailed("Token refresh cancelled")
            }
        }
    }
}
