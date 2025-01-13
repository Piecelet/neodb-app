//
//  AppManager.swift
//  NeoDB
//
//  Created by citron on 1/11/25.
//

import Foundation
import SwiftUI
import OSLog

@MainActor
final class AppManager: ObservableObject {
    static let shared = AppManager()
    private let logger = Logger.auth
    
    @Published private(set) var currentAccount: AppAccount?
    private var networkClient: NetworkClient?
    
    private init() {
        // 初始化默認實例
        currentAccount = AppAccount(instance: "neodb.social")
        networkClient = NetworkClient(instance: "neodb.social")
    }
    
    // MARK: - Account Management
    var currentInstance: String {
        currentAccount?.instance ?? "neodb.social"
    }
    
    var isAuthenticated: Bool {
        currentAccount?.accessToken != nil
    }
    
    func setCurrentAccount(_ account: AppAccount) {
        logger.debug("Setting current account for instance: \(account.instance)")
        self.currentAccount = account
        self.networkClient = NetworkClient(
            instance: account.instance,
            accessToken: account.accessToken
        )
    }
    
    func updateAccessToken(_ token: String?) {
        logger.debug("Updating access token")
        currentAccount?.accessToken = token
        networkClient?.setAccessToken(token)
    }
    
    func clearCurrentAccount() {
        logger.debug("Clearing current account")
        self.currentAccount = AppAccount(instance: "neodb.social")
        self.networkClient = NetworkClient(instance: "neodb.social")
    }
    
    // MARK: - Network Operations
    func fetch<T: Decodable>(_ endpoint: NetworkEndpoint, type: T.Type) async throws -> T {
        guard let client = networkClient else {
            logger.error("No network client available")
            throw AccountError.notAuthenticated
        }
        return try await client.fetch(endpoint, type: type)
    }
    
    func send(_ endpoint: NetworkEndpoint) async throws {
        guard let client = networkClient else {
            logger.error("No network client available")
            throw AccountError.notAuthenticated
        }
        try await client.send(endpoint)
    }
}

