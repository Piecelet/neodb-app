import Foundation
import OSLog
import KeychainSwift

@MainActor
class ClientManager: ObservableObject {
    private let logger = Logger.networkAuth
    private let keychain: KeychainSwift
    
    init() {
        self.keychain = KeychainSwift(keyPrefix: "neodb_")
    }
    
    func getInstanceClient(for instance: String) -> InstanceClient? {
        guard let data = keychain.getData("client_\(instance)"),
              let client = try? JSONDecoder().decode(InstanceClient.self, from: data)
        else { 
            logger.debug("Failed to get client data for instance: \(instance)")
            return nil 
        }
        logger.debug("Retrieved client data for instance: \(instance)")
        return client
    }
    
    func saveInstanceClient(_ client: InstanceClient) {
        if let data = try? JSONEncoder().encode(client) {
            keychain.set(data, forKey: "client_\(client.instance)")
            logger.debug("Saved client data for instance: \(client.instance)")
        } else {
            logger.error("Failed to encode client data for instance: \(client.instance)")
        }
    }
    
    func removeInstanceClient(for instance: String) {
        keychain.delete("client_\(instance)")
        logger.debug("Removed client data for instance: \(instance)")
    }
    
    func registerClient(for instance: String, name: String = "NeoDB", redirectUri: String) async throws -> InstanceClient {
        let baseURL = "https://\(instance)"
        guard let url = URL(string: "\(baseURL)/api/v1/apps") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_name": name,
            "redirect_uris": redirectUri,
            "scopes": "read write"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        logger.debug("Registering app for instance: \(instance)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                throw AuthError.registrationFailed(errorString)
            }
            throw AuthError.registrationFailed("Status code: \(httpResponse.statusCode)")
        }
        
        let registrationResponse = try JSONDecoder().decode(AppRegistrationResponse.self, from: data)
        
        let client = InstanceClient(
            clientId: registrationResponse.client_id,
            clientSecret: registrationResponse.client_secret,
            instance: instance
        )
        
        saveInstanceClient(client)
        logger.debug("App registered successfully with client_id: \(registrationResponse.client_id) for instance: \(instance)")
        
        return client
    }
} 
