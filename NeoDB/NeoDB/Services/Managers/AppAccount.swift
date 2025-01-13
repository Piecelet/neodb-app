//
//  AppAccount.swift
//  NeoDB
//
//  Created by citron on 1/12/25.
//

import Foundation
import KeychainSwift

struct AppAccount: Codable, Identifiable {
    let instance: String
    let oauthToken: OauthToken?
    
    var id: String {
        key
    }
    
    var key: String {
        if let oauthToken {
            return KeychainKeys.account("\(instance):\(oauthToken.createdAt)").key
        } else {
            return KeychainKeys.account("\(instance):anonymous:\(Date().timeIntervalSince1970)").key
        }
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let keychain = KeychainSwift()
        keychain.set(data, forKey: key)
    }
    
    func delete() {
        KeychainSwift().delete(key)
    }
    
    static func retrieveAll() throws -> [AppAccount] {
        let keychain = KeychainSwift(keyPrefix: KeychainKeys.account(nil).prefix)
        let decoder = JSONDecoder()
        let keys = keychain.allKeys
        var accounts: [AppAccount] = []
        for key in keys {
            if let data = keychain.getData(key) {
                let account = try decoder.decode(AppAccount.self, from: data)
                accounts.append(account)
            }
        }
        return accounts
    }
    
    static func deleteAll() {
        let keychain = KeychainSwift()
        let keys = keychain.allKeys
        for key in keys {
            keychain.delete(key)
        }
    }
}
