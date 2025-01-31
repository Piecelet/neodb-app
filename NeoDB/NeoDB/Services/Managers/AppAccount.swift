//
//  AppAccount.swift
//  NeoDB
//
//  Created by citron on 1/12/25.
//

import Foundation
import KeychainSwift
import OSLog

struct AppAccount: Codable, Identifiable, Hashable, Sendable {
    let instance: String
    var accountName: String?
    let oauthToken: OauthToken?

    var id: String {
        key
    }

    private var key: String {
        if let oauthToken {
            return "\(instance):\(oauthToken.createdAt)"
        } else {
            return "\(instance):anonymous:\(Date().timeIntervalSince1970)"
        }
    }

}

extension AppAccount {
    private static let logger = Logger.managers.account
    private static let keychain = KeychainSwift(keyPrefix: KeychainPrefixes.account)

    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        
        Self.logger.debug("Saving account")
        
        if !Self.keychain.set(data, forKey: key) {
            Self.logger.error("Failed to save account")
            throw AccountError.keyChainError("Failed to save account")
        }
        Self.logger.debug("Saved account")
    }

    func delete() {
        Self.logger.debug("Deleting account")
        Self.keychain.delete(key)
        Self.logger.debug("Deleted account")
    }

    static func getKeys() -> [String] {
        let allKeys = Self.keychain.allKeys
        let keys = allKeys.filter { $0.contains(KeychainPrefixes.account) }
        Self.logger.debug("Found \(keys.count) account keys in keychain")
        let cleanedKeys = keys.map { key in
            key.replacingOccurrences(of: KeychainPrefixes.account, with: "")
        }
        return cleanedKeys
    }
    

    static func retrieveAll() throws -> [AppAccount] {
        let decoder = JSONDecoder()
        let keys = getKeys()
        var accounts: [AppAccount] = []
        var invalidKeys: [String] = []
        var hasAuthenticatedAccount = false
        
        logger.debug("Found \(keys.count) keys in keychain")
        
        for key in keys {
            if let data = Self.keychain.getData(key) {
                do {
                    let account = try decoder.decode(AppAccount.self, from: data)
                    accounts.append(account)
                    // 检查是否有授权账户
                    if account.oauthToken != nil {
                        hasAuthenticatedAccount = true
                    }
                    Self.logger.debug("Successfully decoded account")
                } catch {
                    logger.error("Failed to decode account data for key: \(key)")
                    invalidKeys.append(key)
                }
            } else {
                logger.error("No data found for key: \(key)")
                invalidKeys.append(key)
            }
        }
        
        // Clean up invalid keys
        if !invalidKeys.isEmpty {
            logger.debug("Cleaning up \(invalidKeys.count) invalid keys")
            for key in invalidKeys {
                logger.debug(key)
                Self.keychain.delete(key)
            }
        }
        
        // 如果有授权账户，清除所有匿名账户
        if hasAuthenticatedAccount {
            logger.debug("Found authenticated account, cleaning up anonymous accounts")
            deleteAllAnonymous()
            // 重新过滤账户列表，移除匿名账户
            accounts = accounts.filter { $0.oauthToken != nil }
        }
        
        logger.debug("Retrieved \(accounts.count) valid account(s)")
        return accounts
    }

    static func deleteAll() {
        let keys = getKeys()
        logger.debug("Deleting all accounts (\(keys.count) keys)")
        
        for key in keys {
            Self.keychain.delete(key)
        }
        
        logger.debug("Deleted all accounts")
    }

    static func deleteAllAnonymous() {
        let keys = getKeys().filter { $0.contains("anonymous") }
        logger.debug("Deleting all anonymous accounts (\(keys.count) keys)")
        
        for key in keys {
            Self.keychain.delete(key)
        }
        
        logger.debug("Deleted all anonymous accounts")
    }
}
