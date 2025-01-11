import Foundation
import OSLog

@MainActor
class NewAuthService: ObservableObject {
    private let logger = Logger.networkAuth
    private let instanceManager: InstanceManager
    private let clientManager: ClientManager
    private let accountManager: AccountManager
    private var networkClient: NetworkClient
    
    @Published var isRegistering = false
    
    private let redirectUri = "neodb://oauth/callback"
    private let scopes = "read write"
    
    var isAuthenticated: Bool { accountManager.isAuthenticated }
    var accessToken: String? { accountManager.accessToken }
    var currentInstance: String { instanceManager.currentInstance }
    
    init(instanceManager: InstanceManager, clientManager: ClientManager, accountManager: AccountManager) {
        self.instanceManager = instanceManager
        self.clientManager = clientManager
        self.accountManager = accountManager
        self.networkClient = NetworkClient(instance: instanceManager.currentInstance)
        logger.debug("Initialized with instance: \(instanceManager.currentInstance)")
    }
    
    var authorizationURL: URL? {
        guard let client = clientManager.getInstanceClient(for: instanceManager.currentInstance) else { 
            logger.error("Cannot create authorization URL: no client_id available")
            return nil 
        }
        
        var components = URLComponents(string: "\(instanceManager.getBaseURL())/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: client.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes),
            // Add current instance as state to restore it after callback
            URLQueryItem(name: "state", value: instanceManager.currentInstance)
        ]
        logger.debug("Created authorization URL for instance: \(instanceManager.currentInstance)")
        return components?.url
    }
    
    func registerApp() async throws {
        // Check if we already have valid credentials for this instance
        if let client = clientManager.getInstanceClient(for: instanceManager.currentInstance) {
            logger.debug("Using existing client credentials for instance: \(instanceManager.currentInstance), client_id: \(client.clientId)")
            return
        }
        
        isRegistering = true
        defer { isRegistering = false }
        
        let response = try await networkClient.fetch(
            AuthEndpoints.register(
                clientName: "NeoDB iOS App",
                redirectUri: redirectUri,
                scopes: scopes
            ),
            type: AppRegistrationResponse.self
        )
        
        let client = InstanceClient(
            clientId: response.client_id,
            clientSecret: response.client_secret,
            instance: instanceManager.currentInstance
        )
        
        clientManager.saveInstanceClient(client)
        logger.debug("App registered successfully with client_id: \(response.client_id) for instance: \(instanceManager.currentInstance)")
    }
    
    func handleCallback(url: URL) async throws {
        logger.debug("Handling OAuth callback with URL: \(url)")
        
        // Extract instance from saved state if available
        if let state = URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "state" })?
            .value,
           !state.isEmpty && state != "None" {
            // If state contains instance information, use it
            try instanceManager.switchInstance(state)
            logger.debug("Restored instance from state: \(instanceManager.currentInstance)")
            // Update network client with new instance
            networkClient = NetworkClient(instance: instanceManager.currentInstance)
        }
        
        // Verify we have client credentials before proceeding
        guard let client = clientManager.getInstanceClient(for: instanceManager.currentInstance) else {
            logger.error("No client credentials found for instance: \(instanceManager.currentInstance)")
            throw AuthError.noClientCredentials
        }
        logger.debug("Found client credentials for callback, client_id: \(client.clientId)")
        
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
        else {
            logger.error("No authorization code found in callback URL")
            throw AuthError.invalidResponse
        }
        
        logger.debug("Authorization code received: \(code) for instance: \(instanceManager.currentInstance)")
        try await exchangeCodeForToken(code: code, client: client)
    }
    
    private func exchangeCodeForToken(code: String, client: InstanceClient) async throws {
        logger.debug("Exchanging authorization code for token")
        
        let tokenResponse = try await networkClient.fetch(
            AuthEndpoints.token(
                code: code,
                clientId: client.clientId,
                clientSecret: client.clientSecret,
                redirectUri: redirectUri
            ),
            type: OauthToken.self
        )
        
        accountManager.setAccessToken(tokenResponse.accessToken)
        
        // Create and save account
        let account = AppAccount(server: instanceManager.currentInstance, oauthToken: tokenResponse)
        try accountManager.saveAccount(account)
        
        logger.debug("Successfully obtained access token for instance: \(instanceManager.currentInstance)")
    }
    
    func logout() {
        accountManager.logout()
        logger.debug("Logged out from instance: \(instanceManager.currentInstance)")
    }
    
    func clearAllData() {
        // Clear all accounts
        accountManager.logout()
        // Reset instance
        try? instanceManager.switchInstance("neodb.social")
        // Update network client with new instance
        networkClient = NetworkClient(instance: "neodb.social")
        logger.debug("Cleared all data")
    }
} 