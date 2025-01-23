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
    
    private let joinMastodonClient = JoinMastodonClient()
    private var instanceDetailTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                selectedMastodonInstance = nil
                instances = []
                filteredInstances = []
                // Load initial instances list
                Task {
                    await loadInitialInstances()
                }
            }
        }
    }
    
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
        instanceDetailTask?.cancel()
        selectedMastodonInstance = nil
        
        let keyword = mastodonInstance.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check if it's a valid domain
        if sanitizedInstanceName.contains("."), !sanitizedInstanceName.hasSuffix(".") {
            instanceDetailTask = Task {
                try? await Task.sleep(for: .seconds(0.3))
                guard !Task.isCancelled else { return }
                await fetchInstanceDetail()
            }
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
    
    private func fetchInstanceDetail() async {
        do {
            let client = NetworkClient(instance: sanitizedInstanceName)
            let instance = try await client.fetch(
                InstanceEndpoint.instance(instance: sanitizedInstanceName),
                type: MastodonInstance.self)
            
            await MainActor.run {
                withAnimation {
                    self.selectedMastodonInstance = instance
                }
                self.errorMessage = nil
            }
        } catch {
            logger.error("Failed to fetch instance detail: \(error.localizedDescription)")
            selectedMastodonInstance = nil
        }
    }
    
    func selectInstance(_ instance: JoinMastodonServers) {
        withAnimation {
            mastodonInstance = instance.domain
            searchInstances()
        }
    }
    
    func authenticate(using session: WebAuthenticationSession) async {
        guard !mastodonInstance.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            logger.debug("Authenticating with Mastodon instance: \(mastodonInstance)")
            // TODO: Implement authentication
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
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
