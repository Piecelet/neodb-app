//
//  MastodonLoginViewModel.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import AuthenticationServices
import OSLog
import SwiftUI
import WebKit

@MainActor
class MastodonLoginViewModel: NSObject, ObservableObject {
    private let logger = Logger.views.login

    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showInstanceInput = false
    @Published var isLoading = false

    // Two-step states
    @Published var currentStep = 1
    @Published var neodbInstance = ""
    @Published var mastodonInstance = "" {
        didSet {
            if oldValue != mastodonInstance {
                isInstanceChoosenBySelect = false
            }
        }
    }
    @Published var instances: [JoinMastodonServers] = []
    @Published var filteredInstances: [JoinMastodonServers] = []
    @Published var selectedMastodonInstance: MastodonInstance?
    @Published var isInstanceUnavailable = false
    @Published var isAuthenticating = false {
        didSet {
            if oldValue != isAuthenticating {
                accountsManager?.isAuthenticating = isAuthenticating
            }
        }
    }
    @Published var isWebViewPresented = false
    @Published var webViewRequest: URLRequest?

    private let joinMastodonClient = JoinMastodonClient()
    private var instanceDetailTask: Task<Void, Never>?
    private var instanceCheckTask: Task<Void, Never>?

    var accountsManager: AppAccountsManager?

    private var isInstanceChoosenBySelect = false
    private var cookie: String?
    private var csrfToken: String?
    private var refererUrl: URL?
    private var authUrl: URL?
    private var isMastodonAuthorized = false

    var sanitizedInstanceName: String {
        var name =
            mastodonInstance
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

        let keyword = mastodonInstance.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()

        // Check if it's a valid domain
        if sanitizedInstanceName.contains("."),
            !sanitizedInstanceName.hasSuffix(".")
        {
            isLoading = true

            instanceCheckTask = Task { @MainActor in
                do {
                    // Wait briefly before checking
                    try await Task.sleep(for: .seconds(0.3))
                    guard !Task.isCancelled else { return }

                    let client = NetworkClient(instance: sanitizedInstanceName)
                    let instance = try await client.fetch(
                        InstanceEndpoint.instance(
                            instance: sanitizedInstanceName),
                        type: MastodonInstance.self)

                    if !Task.isCancelled {
                        withAnimation {
                            self.selectedMastodonInstance = instance
                            self.isInstanceUnavailable = false
                            if isInstanceChoosenBySelect {
                                self.currentStep = 2
                            }
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
                    server.domain.lowercased().contains(keyword)
                        || server.description.lowercased().contains(keyword)
                }
            }
        }
    }

    func selectInstance(_ instance: JoinMastodonServers) {
        withAnimation {
            mastodonInstance = instance.domain
            searchInstances()
            isInstanceChoosenBySelect = true
        }
    }

    func authenticate() async {
        do {
            if let accountsManager = accountsManager {
                isMastodonAuthorized = false
                isAuthenticating = true
                
                // 1. Get login page and extract CSRF token
                let client = NetworkClient(
                    instance: accountsManager.currentAccount.instance)
                let loginPage = try await client.fetch(
                    NeoDBAccountLoginEndpoint.login, type: HTMLPage.self)

                // 2-3. Store cookie and CSRF token
                var cookies: [String] = []
                if let allHeaderFields = client.lastResponse?.allHeaderFields {
                    for (key, value) in allHeaderFields {
                        if let headerKey = key as? String,
                            headerKey.lowercased() == "set-cookie",
                            let cookieStr = value as? String
                        {
                            if let firstPart = cookieStr.split(separator: ";")
                                .first
                            {
                                cookies.append(String(firstPart))
                            }
                        }
                    }
                }
                cookie = cookies.joined(separator: "; ")
                csrfToken = loginPage.csrfmiddlewaretoken

                // 4-5. Get authenticate URL and path
                let authUrl = try await accountsManager.authenticate(
                    instance: accountsManager.currentAccount.instance)
                guard
                    let components = URLComponents(
                        url: authUrl, resolvingAgainstBaseURL: true),
                    let authenticatePath = components.string?
                        .addingPercentEncoding(
                            withAllowedCharacters: .urlHostAllowed)
                else {
                    throw AccountError.invalidURL
                }

                self.authUrl = authUrl

                // 6. Compose referer URL
                let refererUrlString =
                    "https://\(accountsManager.currentAccount.instance)/account/login?next=\(authenticatePath)"
                guard let refererUrl = URL(string: refererUrlString) else {
                    throw AccountError.invalidURL
                }
                self.refererUrl = refererUrl

                // 7. Create request for mastodon login
                let mastodonLoginEndpoint = NeoDBAccountLoginEndpoint.mastodon(
                    referer: refererUrl,
                    cookie: cookie ?? "",
                    csrfmiddlewaretoken: csrfToken ?? "",
                    instance: mastodonInstance
                )

                // Create URL request directly for WebView
                let url = try accountsManager.currentClient.makeURL(
                    endpoint: mastodonLoginEndpoint)
                var request = URLRequest(url: url)
                request.httpMethod = mastodonLoginEndpoint.method.rawValue

                // Add all required headers
                mastodonLoginEndpoint.headers?.forEach { key, value in
                    request.setValue(value, forHTTPHeaderField: key)
                }

                // Set the request for WebView to load
                self.webViewRequest = request
                isWebViewPresented = true
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isAuthenticating = false
            accountsManager?.isAuthenticating = false
            isWebViewPresented = false
        }
    }

    func handleCallback(url: URL) async throws {
        do {
            if let accountsManager = accountsManager {
                try await accountsManager.handleCallback(url: url)
                isAuthenticating = false
            }
        } catch {
            isAuthenticating = false
            accountsManager?.isAuthenticating = false
            throw error
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

// MARK: - WKNavigationDelegate
extension MastodonLoginViewModel: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .allow
        }

        // Check if URL contains OAuth callback
        if url.absoluteString.starts(with: AppConfig.OAuth.redirectUri) {
            // Handle OAuth callback
            Task { @MainActor in
                do {
                    try await handleCallback(url: url)
                    isAuthenticating = false
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            return .cancel
        }

        // Monitor URL changes
        if let accountsManager = accountsManager {
            print(
                "url: \(url) containsMastodonInstance: \(url.host?.contains(mastodonInstance) == true) isMastodonAuthorized: \(isMastodonAuthorized) containsNeoDBInstance: \(url.host?.contains(accountsManager.currentAccount.instance) == true) containsOauthPath: \(url.path.contains("oauth/authorize") == true) urlPath: \(url.path)"
            )
            if url.host?.contains(mastodonInstance) == true {
                isMastodonAuthorized = true
            } else if url.host?.contains(
                accountsManager.currentAccount.instance) == true,
                isMastodonAuthorized,
                url.path.contains("oauth/authorize") == false
            {
                // If returning to NeoDB from Mastodon, redirect back to auth URL
                if let url = authUrl {
                    isMastodonAuthorized = false
                    webView.load(URLRequest(url: url))
                    return .cancel
                }
            }
        }

        return .allow
    }
}
