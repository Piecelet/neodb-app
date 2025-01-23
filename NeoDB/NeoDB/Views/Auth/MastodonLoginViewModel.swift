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
    @Published var instances: [InstanceSocial] = []
    
    private let instanceSocialClient = InstanceSocialClient()
    private var searchingTask: Task<Void, Never>?
    
    var accountsManager: AppAccountsManager!
    
    func updateNeoDBInstance(_ newInstance: String) {
        let account = AppAccount(instance: newInstance, oauthToken: nil)
        accountsManager.add(account: account)
        showInstanceInput = false
        // Move to next step after instance is selected
        withAnimation {
            currentStep = 2
        }
    }
    
    func searchInstances() {
        searchingTask?.cancel()
        let instanceName = mastodonInstance
        
        searchingTask = Task {
            try? await Task.sleep(for: .seconds(0.1))
            guard !Task.isCancelled else { return }
            
            let instances = await instanceSocialClient.fetchInstances(keyword: instanceName)
            await MainActor.run {
                withAnimation {
                    self.instances = instances
                }
            }
        }
    }
    
    func selectInstance(_ instance: InstanceSocial) {
        withAnimation {
            mastodonInstance = instance.name
        }
    }
    
    func authenticate(using session: WebAuthenticationSession) async {
        guard !mastodonInstance.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement Mastodon authentication
            logger.debug("Authenticating with Mastodon instance: \(mastodonInstance)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
