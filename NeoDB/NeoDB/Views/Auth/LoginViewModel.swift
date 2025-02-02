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
    private var client: NetworkClient?

    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isAuthenticating = false {
        didSet {
            if oldValue != isAuthenticating {
                accountsManager.isAuthenticating = isAuthenticating
            }
        }
    }
    @Published var showInstanceInput = false
    @Published var authUrl: URL?
    @Published var instanceInfo: MastodonInstance?
    @Published var isLoading = false

    var accountsManager: AppAccountsManager!

    func loadInstanceInfo(instance: String? = nil) async {
        isLoading = true
        do {
            let address = instance ?? accountsManager.currentAccount.instance
            client = NetworkClient(instance: address)
            guard let client = client else { return }
            
            let instance = try await client.fetch(InstanceEndpoint.instance(), type: MastodonInstance.self)
            instanceInfo = instance
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func authenticate() async {
        do {
            authUrl = try await accountsManager.authenticate(
                instance: accountsManager.currentAccount.instance)
            isAuthenticating = true
        } catch AccountError.invalidURL {
            errorMessage = "Invalid instance URL"
            showError = true
            isAuthenticating = false
        } catch AccountError.registrationFailed(let message) {
            errorMessage = "Registration failed: \(message)"
            showError = true
            isAuthenticating = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isAuthenticating = false
        }
    }

    func handleCallback(url: URL) async throws {
        try await accountsManager.handleCallback(url: url)
    }

    func updateInstance(_ newInstance: String) {
        let account = AppAccount(instance: newInstance, oauthToken: nil)
        accountsManager.add(account: account)
        showInstanceInput = false
        
        // Load instance info after updating instance
        Task {
            await loadInstanceInfo(instance: newInstance)
        }
    }
}
