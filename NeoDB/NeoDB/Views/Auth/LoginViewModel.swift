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
    @Published var authUrl: URL?

    var accountsManager: AppAccountsManager!

    func authenticate() async {
        do {
            authUrl = try await accountsManager.authenticate(
                instance: accountsManager.currentAccount.instance)
        } catch AccountError.invalidURL {
            errorMessage = "Invalid instance URL"
            showError = true
            accountsManager.isAuthenticating = false
        } catch AccountError.registrationFailed(let message) {
            errorMessage = "Registration failed: \(message)"
            showError = true
            accountsManager.isAuthenticating = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            accountsManager.isAuthenticating = false
        }
    }

    func handleCallback(url: URL) async throws {
        try await accountsManager.handleCallback(url: url)
    }

    func updateInstance(_ newInstance: String) {
        let account = AppAccount(instance: newInstance, oauthToken: nil)
        accountsManager.add(account: account)
        showInstanceInput = false
    }
}
