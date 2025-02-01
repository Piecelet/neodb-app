//
//  AppAccountsManager.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import OSLog
import SwiftUI

@MainActor
class AppAccountsManager: ObservableObject {
    private let logger = Logger.managers.accountsManager
    private let redirectUri = AppConfig.OAuth.redirectUri
    private var oauthClient: AppClient?

    @AppStorage("latestCurrentAccountKey") static public
        var latestCurrentAccountKey: String = ""

    @AppStorage("lastAuthenticatedAccountKey") static public
        var lastAuthenticatedAccountKey: String = ""

    @AppStorage("hasShownPurchaseView") private var hasShownPurchaseView = false

    @Published var currentAccount: AppAccount {
        didSet {
            Self.lastAuthenticatedAccountKey = Self.latestCurrentAccountKey
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
    @Published var isRefreshing: Bool = false
    @Published var shouldShowPurchase = false {
        didSet {
            logger.debug("shouldShowPurchase changed to \(shouldShowPurchase)")
        }
    }
    @Published var error: Error?

    // 检查是否至少有一个账号已验证
    var isAppAuthenticated: Bool {
        availableAccounts.contains { $0.oauthToken != nil } && !isRefreshing
    }

    init() {
        var defaultAccount = AppAccount(
            instance: AppConfig.defaultInstance, oauthToken: nil)
        do {
            // 删除所有匿名账户
            AppAccount.deleteAllAnonymous()
            
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

        // 如果当前账户已验证，更新lastAuthenticatedAccountKey
        if isAuthenticated {
            Self.lastAuthenticatedAccountKey = currentAccount.id
        }
        
        // 异步更新没有handle的已验证账户信息
        Task { [weak self] in
            guard let self = self else { return }
            
            for account in availableAccounts where account.oauthToken != nil && account.handle == nil {
                do {
                    logger.debug("Updating user info for account: \(account.id)")
                    let updatedAccount = try await fetchAndUpdateUserInfo(for: account)
                    try updatedAccount.save()
                    
                    await MainActor.run {
                        if let index = self.availableAccounts.firstIndex(where: { $0.id == account.id }) {
                            self.availableAccounts[index] = updatedAccount
                            // 如果是当前账户，也更新currentAccount
                            if self.currentAccount.id == account.id {
                                self.currentAccount = updatedAccount
                            }
                        }
                    }
                    logger.debug("Successfully updated user info for account: \(account.id)")
                } catch {
                    logger.error("Failed to update user info for account \(account.id): \(error.localizedDescription)")
                }
            }
        }
    }

    // 删除所有匿名账户并更新可用账户列表
    private func deleteAllAnonymousAndUpdate() {
        AppAccount.deleteAllAnonymous()
        // 重新加载账户列表
        if let accounts = try? AppAccount.retrieveAll() {
            availableAccounts = accounts
        }
        logger.debug("Updated available accounts after deleting anonymous accounts")
    }

    // 获取并更新账户的用户信息
    private func fetchAndUpdateUserInfo(for account: AppAccount) async throws
        -> AppAccount
    {
        // 创建新的NetworkClient用于此次请求
        let client = NetworkClient(
            instance: account.instance,
            oauthToken: account.oauthToken
        )

        // 获取用户信息
        guard
            let user = try? await client.fetch(
                UserEndpoint.me,
                type: User.self
            )
        else {
            throw AccountError.invalidResponse
        }

        // 创建更新后的账户
        var updatedAccount = account
        updatedAccount.username = user.username
        updatedAccount.displayName = user.displayName
        updatedAccount.avatar = user.avatar.absoluteString

        return updatedAccount
    }

    func add(account: AppAccount) {
        // 删除所有匿名账户
        deleteAllAnonymousAndUpdate()

        // 如果是已授权账户
        if account.oauthToken != nil {
            withAnimation {
                // 检查是否存在相同handle的账号
                if let existingIndex = availableAccounts.firstIndex(where: { 
                    $0.handle == account.handle 
                }) {
                    // 删除旧账号
                    let oldAccount = availableAccounts[existingIndex]
                    logger.debug("Removing existing account with handle: \(String(describing: oldAccount.handle))")
                    oldAccount.delete()
                    availableAccounts.remove(at: existingIndex)
                }

                // 保存并添加新账号
                do {
                    try account.save()
                    logger.debug("Successfully saved account with handle: \(String(describing: account.handle))")
                } catch {
                    logger.error("Failed to save account: \(error.localizedDescription)")
                }
                availableAccounts.append(account)
                currentAccount = account
                isAuthenticated = true

                // 更新lastAuthenticatedAccountKey
                Self.lastAuthenticatedAccountKey = account.id
                logger.debug("Updated lastAuthenticatedAccountKey to: \(account.id)")
            }
        } else {
            // 对于未验证的账号，直接保存
            do {
                try account.save()
                logger.debug("Saved anonymous account for instance: \(account.instance)")
            } catch {
                logger.error("Failed to save anonymous account: \(error.localizedDescription)")
            }
            withAnimation {
                if !availableAccounts.contains(where: { $0.id == account.id }) {
                    availableAccounts.append(account)
                }
                currentAccount = account
                isAuthenticated = false
            }
        }
    }

    func delete(account: AppAccount) {
        Task {
            let client = try await AppClient.get(for: currentAccount.instance)
            oauthClient = client
            logger.debug(
                "Client: \(String(describing: oauthClient)), token: \(String(describing: account.oauthToken?.accessToken))"
            )
            if let client = oauthClient,
                let token = account.oauthToken?.accessToken
            {
                _ = try? await currentClient.fetch(
                    OauthEndpoint.revoke(
                        clientId: client.clientId,
                        clientSecret: client.clientSecret, token: token),
                    type: Data.self)
            }
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
            logger.debug(
                "Last account deleted, reset hasShownPurchaseView to false")
        }
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
            URLQueryItem(name: "state", value: currentAccount.instance),
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

    func handleCallback(url: URL, ignoreAuthenticationDuration: Bool = false)
        async throws
    {
        guard isAuthenticating && ignoreAuthenticationDuration != true else {
            logger.error("Received callback but not in authentication process")
            throw AccountError.authenticationFailed(
                "Not in authentication process")
        }

        guard let client = oauthClient else {
            logger.error("No OAuth client available")
            throw AccountError.authenticationFailed("No OAuth client available")
        }

        // Extract instance from state
        guard
            let components = URLComponents(
                url: url, resolvingAgainstBaseURL: true),
            let state = components.queryItems?.first(where: {
                $0.name == "state"
            })?.value,
            let code = components.queryItems?.first(where: { $0.name == "code" }
            )?.value
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

            // 创建新账户
            let account = AppAccount(instance: state, oauthToken: token)
            logger.debug("Created new account for instance: \(state)")

            // 获取用户信息并更新账户
            let updatedAccount = try await fetchAndUpdateUserInfo(for: account)
            logger.debug("Updated account info - handle: \(String(describing: updatedAccount.handle))")

            // 添加更新后的账户
            add(account: updatedAccount)

            logger.debug(
                "After adding account, shouldShowPurchase: \(shouldShowPurchase)"
            )
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
        logger.debug("Authentication process completed, isAuthenticating set to false")
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
            let token = try await networkClient.fetch(
                endpoint, type: OauthToken.self)
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
                throw AccountError.tokenRefreshFailed(
                    "Failed to decode response")
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

        if account.oauthToken != nil {
            Self.lastAuthenticatedAccountKey = account.id
            deleteAllAnonymousAndUpdate()
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

    // 恢复到上一个已验证的账号
    func restoreLastAuthenticatedAccount() {
        logger.debug("Attempting to restore last authenticated account")
        logger.debug("Last authenticated account key: \(Self.lastAuthenticatedAccountKey)")
        logger.debug("Available accounts: \(availableAccounts.map { $0.id })")
        
        guard !Self.lastAuthenticatedAccountKey.isEmpty else {
            logger.debug("No last authenticated account key found")
            return
        }
        
        guard let lastAccount = availableAccounts.first(where: {
            $0.id == Self.lastAuthenticatedAccountKey
        }) else {
            logger.debug("Last authenticated account not found in available accounts")
            return
        }

        // 只有当上一个账号是已验证的才进行恢复
        if lastAccount.oauthToken != nil {
            logger.debug("Switching to last authenticated account: \(lastAccount.id)")
            switchAccount(lastAccount)
        } else {
            logger.debug("Last account found but not authenticated: \(lastAccount.id)")
        }
    }
}
