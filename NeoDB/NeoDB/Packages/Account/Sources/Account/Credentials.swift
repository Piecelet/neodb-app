import Foundation
import KeychainSwift

public struct Credentials: Codable {
    public let clientId: String
    public let clientSecret: String
    public let accessToken: String?
    public let server: String
    
    public init(
        clientId: String,
        clientSecret: String,
        accessToken: String? = nil,
        server: String
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.accessToken = accessToken
        self.server = server
    }
}

public class CredentialsStore {
    private let keychain: KeychainSwift
    private let credentialsKey = "neodb.credentials"
    
    public init() {
        self.keychain = KeychainSwift()
    }
    
    public func save(_ credentials: Credentials) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(credentials)
        let jsonString = String(data: data, encoding: .utf8)!
        keychain.set(jsonString, forKey: credentialsKey)
    }
    
    public func load() -> Credentials? {
        guard let jsonString = keychain.get(credentialsKey),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(Credentials.self, from: data)
    }
    
    public func clear() {
        keychain.delete(credentialsKey)
    }
} 