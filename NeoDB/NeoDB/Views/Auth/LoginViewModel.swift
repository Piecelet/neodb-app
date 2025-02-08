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

    // State
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isAuthenticating = false {
        didSet {
            if oldValue != isAuthenticating {
                accountsManager?.isAuthenticating = isAuthenticating
            }
        }
    }
    @Published var isAuthLoading = false
    @Published var authUrl: URL?
    @Published var instanceInfo: MastodonInstance?
    @Published var isLoading = false
    @Published var showMastodonLogin = false
    @Published var canDismiss = false
    @Published var buttonScale = 1.0
    
    // Dependencies
    var accountsManager: AppAccountsManager?

    let instanceAddress: String
    
    init(instanceAddress: String) {
        self.instanceAddress = instanceAddress
        logger.debug("LoginViewModel initialized with instanceAddress: \(instanceAddress)")
    }

    func initialize() {
        if accountsManager != nil,
        instanceInfo == nil {
            Task {
                await loadInstanceInfo()
            }
        }
    }

    func loadInstanceInfo() async {
        isLoading = true
        do {
            guard accountsManager?.currentClient != nil else { return }
            
            let instance = try await accountsManager?.currentClient.fetch(InstanceEndpoint.instance(), type: MastodonInstance.self)
            instanceInfo = instance
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func authenticate() async {
        do {
            isAuthLoading = true
            authUrl = try await accountsManager?.authenticate(
                instance: accountsManager?.currentAccount.instance ?? AppConfig.defaultInstance)
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
        isAuthLoading = false
    }

    func handleCallback(url: URL) async throws {
        try await accountsManager?.handleCallback(url: url)
    }
    
    func handleSignInButtonTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }

        // Reset scale after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                self.buttonScale = 1.0
            }
        }

        Task {
            await authenticate()
            accountsManager?.isAuthenticating = true
        }
    }
}
