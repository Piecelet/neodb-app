//
//  KeychainSwift.swift
//  NeoDB
//
//  Created by citron on 1/11/25.
//

import KeychainSwift

enum KeychainKeys {
    case account(String?)
    case client(String?)

    var prefix: String {
        switch self {
        case .account:
            return "account_"
        case .client:
            return "client_"
        }
    }
    
    var key: String {
        switch self {
        case .account(let instance):
            return "\(self.prefix)\(instance?.lowercased() ?? "")"
        case .client(let instance):
            return "\(self.prefix)\(instance?.lowercased() ?? "")"
        }
    }
}
