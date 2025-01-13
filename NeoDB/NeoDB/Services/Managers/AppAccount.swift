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
    private static let keychain = KeychainSwift(keyPrefix: KeychainKeys.account(nil).prefix)
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

        if !Self.keychain.set(data, forKey: key) {
            Self.logger.error(
                "Failed to save account for instance: \(instance)")
            throw AccountError.keyChainError("Failed to save account")
        }
        Self.logger.debug("Saved account for instance: \(instance)")
    }

    func delete() {
        Self.keychain.delete(key)
        Self.logger.debug("Deleted account for instance: \(instance)")
    }

    static func retrieveAll() throws -> [AppAccount] {
        let decoder = JSONDecoder()
        let keys = keychain.allKeys
        var accounts: [AppAccount] = []

        for key in keys {
            if let data = keychain.getData(key) {
                do {
                    let account = try decoder.decode(
                        AppAccount.self, from: data)
                    accounts.append(account)
                } catch {
                    logger.error(
                        "Failed to decode account data for key: \(key), error: \(error.localizedDescription)"
                    )
                    throw error
                }
            }
        }

        logger.debug("Retrieved \(accounts.count) account(s)")
        return accounts
    }

    static func deleteAll() {
        let keys = keychain.allKeys
        for key in keys {
            keychain.delete(key)
        }
        logger.debug("Deleted all accounts")
    }
}
