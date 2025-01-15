//
//  AppAccount.swift
//  NeoDB
//
//  Created by citron on 1/12/25.
//

import Foundation
import KeychainSwift
import OSLog

struct AppAccount: Codable, Identifiable {
    private static let logger = Logger.managers.account
    
    let instance: String
    let oauthToken: OauthToken?

    var id: String {
        key
    }

    var key: String {
        if let oauthToken {
            return "\(instance):\(oauthToken.createdAt)"
        } else {
            return "\(instance):anonymous:\(Date().timeIntervalSince1970)"
        }
    }

    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let keychain = KeychainSwift()
        
        Self.logger.debug("Saving account")
        
        if !keychain.set(data, forKey: key) {
            Self.logger.error("Failed to save account")
            throw AccountError.keyChainError("Failed to save account")
        }
        Self.logger.debug("Saved account")
    }

    func delete() {
        let keychain = KeychainSwift()
        Self.logger.debug("Deleting account")
        keychain.delete(key)
        Self.logger.debug("Deleted account")
    }

    static func retrieveAll() throws -> [AppAccount] {
        let keychain = KeychainSwift()
        let decoder = JSONDecoder()
        let keys = keychain.allKeys
        var accounts: [AppAccount] = []
        
        logger.debug("Found \(keys.count) keys in keychain")
        
        for key in keys {
            if let data = keychain.getData(key) {
                do {
                    let account = try decoder.decode(AppAccount.self, from: data)
                    accounts.append(account)
                    logger.debug("Successfully decoded account")
                } catch {
                    logger.error("Failed to decode account data")
                    throw error
                }
            }
        }
        
        logger.debug("Retrieved \(accounts.count) account(s)")
        return accounts
    }

    static func deleteAll() {
        let keychain = KeychainSwift()
        let keys = keychain.allKeys
        logger.debug("Deleting all accounts (\(keys.count) keys)")
        
        for key in keys {
            keychain.delete(key)
        }
        
        logger.debug("Deleted all accounts")
    }
}
