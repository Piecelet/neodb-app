//
//  MastodonLoginViewModel.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import SwiftUI
import OSLog
import AuthenticationServices

@MainActor
class MastodonLoginViewModel: ObservableObject {
    private let logger = Logger.views.login
    
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showInstanceInput = false
    @Published var isLoading = false
    
    // Two-step states
    @Published var currentStep = 1
    @Published var neodbInstance = ""
    @Published var mastodonInstance = ""
    @Published var instances: [JoinMastodonServers] = []
    @Published var filteredInstances: [JoinMastodonServers] = []
    @Published var selectedMastodonInstance: MastodonInstance?
    @Published var isInstanceUnavailable = false
    @Published var isAuthenticating = false
    @Published var authUrl: URL?
    
    private let joinMastodonClient = JoinMastodonClient()
    private var instanceDetailTask: Task<Void, Never>?
    private var instanceCheckTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager!
    
    var sanitizedInstanceName: String {
        var name = mastodonInstance
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if name.contains("@") {
            let parts = name.components(separatedBy: "@")
            name = parts[parts.count - 1]
        }
        return name
    }
    
    func updateNeoDBInstance(_ newInstance: String) {
        guard let accountsManager = accountsManager else { return }
        let account = AppAccount(instance: newInstance, oauthToken: nil)
        accountsManager.add(account: account)
        showInstanceInput = false
        withAnimation {
            currentStep = 2
        }
    }
    
    // Load initial instances list
    func loadInitialInstances() async {
        let servers = await joinMastodonClient.fetchServers()
        await MainActor.run {
            withAnimation {
                self.instances = servers
                self.filteredInstances = servers
            }
        }
    }
    
    func searchInstances() {
        // Cancel any existing check
        instanceCheckTask?.cancel()
        selectedMastodonInstance = nil
        isInstanceUnavailable = false
        
        let keyword = mastodonInstance.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check if it's a valid domain
        if sanitizedInstanceName.contains("."), !sanitizedInstanceName.hasSuffix(".") {
            isLoading = true
            
            instanceCheckTask = Task { @MainActor in
                do {
                    // Wait briefly before checking
                    try await Task.sleep(for: .seconds(0.3))
                    guard !Task.isCancelled else { return }
                    
                    let client = NetworkClient(instance: sanitizedInstanceName)
                    let instance = try await client.fetch(
                        InstanceEndpoint.instance(instance: sanitizedInstanceName),
                        type: MastodonInstance.self)
                    
                    if !Task.isCancelled {
                        withAnimation {
                            self.selectedMastodonInstance = instance
                            self.isInstanceUnavailable = false
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        // Wait before showing unavailable
                        try? await Task.sleep(for: .seconds(3))
                        if !Task.isCancelled {
                            withAnimation {
                                self.isInstanceUnavailable = true
                            }
                        }
                    }
                }
                
                if !Task.isCancelled {
                    isLoading = false
                }
            }
        } else {
            isLoading = false
        }
        
        // Local search
        withAnimation {
            if keyword.isEmpty {
                filteredInstances = instances
            } else {
                filteredInstances = instances.filter { server in
                    server.domain.lowercased().contains(keyword) ||
                    server.description.lowercased().contains(keyword)
                }
            }
        }
    }
    
    func selectInstance(_ instance: JoinMastodonServers) {
        withAnimation {
            mastodonInstance = instance.domain
            searchInstances()
        }
    }
    
    func authenticate() async {
        do {
            authUrl = try await accountsManager.authenticate(
                instance: accountsManager.currentAccount.instance)
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
    
    func validateAndContinue() -> Bool {
        guard !mastodonInstance.isEmpty else { return false }
        
        // Only validate instance support when trying to continue
        if selectedMastodonInstance == nil {
            errorMessage = "This instance is not supported"
            showError = true
            return false
        }
        
        return true
    }
}
