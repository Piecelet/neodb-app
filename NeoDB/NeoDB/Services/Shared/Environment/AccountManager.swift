import Foundation
import OSLog
import KeychainSwift

struct AppAccount: Codable, Identifiable {
    let server: String
    let oauthToken: OauthToken?
    
    var id: String {
        key
    }
    
    var key: String {
        if let oauthToken {
            return "\(server):\(oauthToken.createdAt)"
        } else {
            return "\(server):anonymous:\(Date().timeIntervalSince1970)"
        }
    }
}

@MainActor
class AccountManager: ObservableObject {
    private let logger = Logger.networkAuth
    private let keychain: KeychainSwift
    
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var currentAccount: AppAccount?
    
    init() {
        self.keychain = KeychainSwift(keyPrefix: "neodb_")
        
        // Check if we have a saved access token
        if let token = savedAccessToken {
            accessToken = token
            isAuthenticated = true
            logger.debug("Found saved access token")
        }
    }
    
    private var savedAccessToken: String? {
        get { keychain.get("access_token") }
        set {
            if let value = newValue {
                keychain.set(value, forKey: "access_token")
                accessToken = value
                isAuthenticated = true
                logger.debug("Saved access token")
            } else {
                keychain.delete("access_token")
                accessToken = nil
                isAuthenticated = false
                logger.debug("Removed access token")
            }
        }
    }
    
    func saveAccount(_ account: AppAccount) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(account)
        keychain.set(data, forKey: account.key)
        currentAccount = account
        logger.debug("Saved account for server: \(account.server)")
    }
    
    func deleteAccount(_ account: AppAccount) {
        keychain.delete(account.key)
        if currentAccount?.id == account.id {
            currentAccount = nil
        }
        logger.debug("Deleted account for server: \(account.server)")
    }
    
    static func retrieveAll() throws -> [AppAccount] {
        let keychain = KeychainSwift(keyPrefix: "neodb_")
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
    
    func logout() {
        savedAccessToken = nil
        if let account = currentAccount {
            deleteAccount(account)
        }
        logger.info("User logged out")
    }
    
    func setAccessToken(_ token: String) {
        savedAccessToken = token
    }
} 