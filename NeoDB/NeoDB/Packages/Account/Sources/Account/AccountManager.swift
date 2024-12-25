import Foundation
import Network
import Config

public enum AccountError: Error {
    case invalidServer
    case authenticationFailed
    case credentialsNotFound
}

@MainActor
public class AccountManager: ObservableObject {
    private let credentialsStore: CredentialsStore
    private let serverConfig: ServerConfiguration
    private var api: NeoDBAPI?
    private var authService: AuthenticationService?
    
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var currentUser: NeoDBUser?
    
    public init(
        credentialsStore: CredentialsStore = CredentialsStore(),
        serverConfig: ServerConfiguration = ServerConfiguration()
    ) {
        self.credentialsStore = credentialsStore
        self.serverConfig = serverConfig
        
        if let credentials = credentialsStore.load() {
            serverConfig.updateServer(credentials.server)
            isAuthenticated = credentials.accessToken != nil
            setupAPI(server: credentials.server)
        }
    }
    
    private func setupAPI(server: String) {
        guard let serverURL = URL(string: "https://\(server)") else { return }
        api = NeoDBAPI(baseURL: serverURL)
        if let api = api {
            authService = AuthenticationService(api: api)
        }
    }
    
    public func updateServer(_ server: String) {
        serverConfig.updateServer(server)
        setupAPI(server: server)
    }
    
    public func signIn() async throws {
        guard let api = api else {
            throw AccountError.invalidServer
        }
        
        // Create application if no credentials stored
        let credentials = credentialsStore.load()
        let (clientId, clientSecret) = try await {
            if let existing = credentials {
                return (existing.clientId, existing.clientSecret)
            } else {
                let app = try await api.createApplication(
                    clientName: "NeoDB iOS",
                    redirectURI: "neodb://oauth"
                )
                let newCredentials = Credentials(
                    clientId: app.clientId,
                    clientSecret: app.clientSecret,
                    server: serverConfig.currentServer
                )
                try credentialsStore.save(newCredentials)
                return (app.clientId, app.clientSecret)
            }
        }()
        
        // Perform OAuth flow
        guard let authService = authService else {
            throw AccountError.authenticationFailed
        }
        
        let token = try await authService.authenticate(
            clientId: clientId,
            clientSecret: clientSecret
        )
        
        // Save credentials with access token
        let updatedCredentials = Credentials(
            clientId: clientId,
            clientSecret: clientSecret,
            accessToken: token.accessToken,
            server: serverConfig.currentServer
        )
        try credentialsStore.save(updatedCredentials)
        
        // Fetch user info
        currentUser = try await api.getCurrentUser(accessToken: token.accessToken)
        isAuthenticated = true
    }
    
    public func signOut() {
        credentialsStore.clear()
        currentUser = nil
        isAuthenticated = false
    }
} 