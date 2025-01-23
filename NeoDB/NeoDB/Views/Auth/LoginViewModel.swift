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
    @Published var isAuthenticating = false
    @Published var showInstanceInput = false
    @Published var authUrl: URL?

    var accountsManager: AppAccountsManager!

    func authenticate() async {
        do {
            isAuthenticating = true
            accountsManager.isAuthenticating = true
            
            let url = try await accountsManager.authenticate(instance: accountsManager.currentAccount.instance)
            self.authUrl = url
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isAuthenticating = false
            accountsManager.isAuthenticating = false
        }
    }

    func handleCallback(url: URL) async throws {
        do {
            try await accountsManager.handleCallback(url: url)
            isAuthenticating = false
            accountsManager.isAuthenticating = false
        } catch {
            isAuthenticating = false
            accountsManager.isAuthenticating = false
            throw error
        }
    }

    func updateInstance(_ newInstance: String) {
        let account = AppAccount(instance: newInstance, oauthToken: nil)
        accountsManager.add(account: account)
        showInstanceInput = false
    }
}
