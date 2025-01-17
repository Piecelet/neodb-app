//
//  LoginViewModel.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import AuthenticationServices
import OSLog
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {
    private let logger = Logger.views.login

    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showInstanceInput = false

    var accountsManager: AppAccountsManager!

    func authenticate(using session: WebAuthenticationSession) async {
        do {
            let authUrl = try await accountsManager.authenticate(
                instance: accountsManager.currentAccount.instance)

            do {
                let url = try await session.authenticate(
                    using: authUrl,
                    callbackURLScheme: AppConfig.OAuth.redirectUri
                        .addingPercentEncoding(
                            withAllowedCharacters: .urlHostAllowed)
                        ?? AppConfig.OAuth.redirectUri.replacingOccurrences(
                            of: "://", with: ""),
                    preferredBrowserSession: WebAuthenticationSession
                        .BrowserSession.shared
                )
                logger.debug("Received callback URL: \(url.absoluteString)")
                try await accountsManager.handleCallback(url: url)
            } catch {
                // Silently handle cancellation
                accountsManager.isAuthenticating = false
                return
            }

        } catch AccountError.invalidURL {
            errorMessage = "Invalid instance URL"
            showError = true
            accountsManager.isAuthenticating = false
        } catch AccountError.registrationFailed(let message) {
            errorMessage = "Registration failed: \(message)"
            showError = true
            accountsManager.isAuthenticating = false
        } catch AccountError.authenticationFailed(let message) {
            errorMessage = "Authentication failed: \(message)"
            showError = true
            accountsManager.isAuthenticating = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            accountsManager.isAuthenticating = false
        }
    }

    func updateInstance(_ newInstance: String) {
        let account = AppAccount(instance: newInstance, oauthToken: nil)
        accountsManager.add(account: account)
        showInstanceInput = false
    }
}
