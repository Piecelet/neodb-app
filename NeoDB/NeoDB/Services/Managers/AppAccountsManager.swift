//
//  AppAccountsManager.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import SwiftUI
import OSLog

@MainActor
class AppAccountsManager: ObservableObject {
    private let logger = Logger.managers.accountsManager
    private let redirectUri = AppConfig.OAuth.redirectUri
    private var oauthClient: AppClient?
    
    @AppStorage("latestCurrentAccountKey") static public
        var latestCurrentAccountKey: String = ""

    @AppStorage("hasShownPurchaseView") private var hasShownPurchaseView = false {
        didSet {
            logger.debug("hasShownPurchaseView changed to \(hasShownPurchaseView)")
        }
    }
    
    @Published var currentAccount: AppAccount {
        didSet {
            Self.latestCurrentAccountKey = currentAccount.id
            currentClient = NetworkClient(
                instance: currentAccount.instance,
                oauthToken: currentAccount.oauthToken
            )
            isAuthenticated = currentAccount.oauthToken != nil
            
            // 发送账号切换通知
            NotificationCenter.default.post(
                name: .accountSwitched,
                object: nil,
                userInfo: ["accountId": currentAccount.id]
            )
            
            // 如果切换到新账号，清除错误状态
            error = nil
            isAuthenticating = false
        }
    }
    @Published var availableAccounts: [AppAccount]
    @Published var currentClient: NetworkClient
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var shouldShowPurchase = false {
        didSet {
            logger.debug("shouldShowPurchase changed to \(shouldShowPurchase)")
        }
    }
    @Published var error: Error?

    init() {
        var defaultAccount = AppAccount(
            instance: AppConfig.defaultInstance, oauthToken: nil)
        do {
            let keychainAccounts = try AppAccount.retrieveAll()
            availableAccounts = keychainAccounts
            if let currentAccount = keychainAccounts.first(where: {
                $0.id == Self.latestCurrentAccountKey
            }) {
                defaultAccount = currentAccount
            } else {
                defaultAccount = keychainAccounts.last ?? defaultAccount
            }
        } catch {
            availableAccounts = [defaultAccount]
        }
        currentAccount = defaultAccount
        currentClient = NetworkClient(
            instance: defaultAccount.instance,
            oauthToken: defaultAccount.oauthToken
        )
        isAuthenticated = defaultAccount.oauthToken != nil
    }

    func add(account: AppAccount) {
        // 删除所有匿名账户
        AppAccount.deleteAllAnonymous()
        
        Task {
            do {
                // 如果是已授权账户，尝试获取用户信息并检查重复
                if account.oauthToken != nil {
                    if let newUser = try? await currentClient.fetch(UserEndpoint.me, type: User.self) {
                        // 检查是否已存在相同实例和用户名的账号
                        for existingAccount in availableAccounts {
                            if existingAccount.instance == account.instance {
                                // 获取已存在账户的用户信息
                                let client = NetworkClient(
                                    instance: existingAccount.instance,
                                    oauthToken: existingAccount.oauthToken
                                )
                                if let existingUser = try? await client.fetch(UserEndpoint.me, type: User.self),
                                   existingUser.username == newUser.username {
                                    // 如果存在相同用户名的账号，切换到该账号
                                    await MainActor.run {
                                        switchAccount(existingAccount)
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
                
                try account.save()
                
                await MainActor.run {
                    withAnimation {
                        // 重新加载账户列表，因为可能有匿名账户被删除
                        if let accounts = try? AppAccount.retrieveAll() {
                            availableAccounts = accounts
                        }
                        // 添加新账户到列表末尾
                        if !availableAccounts.contains(where: { $0.id == account.id }) {
                            availableAccounts.append(account)
                        }
                        currentAccount = account
                        isAuthenticated = account.oauthToken != nil
                    }
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to add account: \(error.localizedDescription)")
                    self.error = error
                }
            }
        }
    }

    func delete(account: AppAccount) {
        availableAccounts.removeAll(where: { $0.id == account.id })
        account.delete()
        if currentAccount.id == account.id {
            currentAccount =
                availableAccounts.first
                ?? AppAccount(instance: "neodb.social", oauthToken: nil)
            isAuthenticated = currentAccount.oauthToken != nil
        }
        
        // Reset hasShownPurchaseView when deleting the last account
            shouldShowPurchase = false
            hasShownPurchaseView = false
            logger.debug("Last account deleted, reset hasShownPurchaseView to false")
    }
    
    // MARK: - Authentication
    
    var authenticationUrl: URL? {
        guard let client = oauthClient else { return nil }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = currentAccount.instance
        components.path = "/oauth/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: client.clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read write"),
            URLQueryItem(name: "state", value: currentAccount.instance)
        ]
        
        return components.url
    }
    
    func authenticate(instance: String) async throws -> URL {
        // Get app client (will register if needed)
        let client = try await AppClient.get(for: instance)
        oauthClient = client
        
        guard let url = authenticationUrl else {
            throw AccountError.invalidURL
        }
        
        logger.debug("Generated OAuth URL")
        return url
    }
    
    func handleCallback(url: URL, ignoreAuthenticationDuration: Bool = false) async throws {
        guard (isAuthenticating && ignoreAuthenticationDuration != true) else {
            logger.error("Received callback but not in authentication process")
            throw AccountError.authenticationFailed("Not in authentication process")
        }
        
        guard let client = oauthClient else {
            logger.error("No OAuth client available")
            throw AccountError.authenticationFailed("No OAuth client available")
        }
        
        // Extract instance from state
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            logger.error("Invalid callback URL")
            throw AccountError.invalidURL
        }
        
        do {
            let token = try await exchangeCodeForToken(
                code: code,
                client: client,
                instance: state
            )
            
            logger.debug("Authentication successful, hasShownPurchaseView: \(hasShownPurchaseView)")
            let account = AppAccount(instance: state, oauthToken: token)
            add(account: account)
            isAuthenticated = true
            logger.debug("After adding account, shouldShowPurchase: \(shouldShowPurchase)")
            if isAuthenticated, !hasShownPurchaseView {
                hasShownPurchaseView = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    shouldShowPurchase = true
                }
            } else {
                shouldShowPurchase = false
            }
        } catch {
            logger.error("Token exchange failed")
            throw error
        }
        
        isAuthenticating = false
        oauthClient = nil
    }
    
    private func exchangeCodeForToken(
        code: String,
        client: AppClient,
        instance: String
    ) async throws -> OauthToken {
        let networkClient = NetworkClient(instance: instance)
        let endpoint = OauthEndpoint.token(
            code: code,
            clientId: client.clientId,
            clientSecret: client.clientSecret,
            redirectUri: redirectUri
        )
        
        do {
            let token = try await networkClient.fetch(endpoint, type: OauthToken.self)
            logger.debug("Successfully exchanged code for token")
            return token
        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                throw AccountError.invalidURL
            case .invalidResponse:
                throw AccountError.invalidResponse
            case .httpError(let code):
                throw AccountError.tokenRefreshFailed("HTTP error: \(code)")
            case .decodingError:
                throw AccountError.tokenRefreshFailed("Failed to decode response")
            case .networkError:
                throw AccountError.tokenRefreshFailed("Network error")
            case .unauthorized:
                throw AccountError.tokenRefreshFailed("Unauthorized")
            case .cancelled:
                throw AccountError.tokenRefreshFailed("Token refresh cancelled")
            }
        }
    }

    func switchAccount(_ account: AppAccount) {
        guard account.id != currentAccount.id else { return }
        
        withAnimation {
            currentAccount = account
        }
        
        // 预加载账号数据
        Task {
            await preloadAccountData()
        }
    }
    
    private func preloadAccountData() async {
        guard isAuthenticated else { return }
        
        do {
            _ = try await currentClient.fetch(UserEndpoint.me, type: User.self)
        } catch {
            self.error = error
        }
    }
}
