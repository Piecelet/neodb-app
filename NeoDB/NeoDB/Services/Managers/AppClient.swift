//
//  AppClient.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation
import KeychainSwift
import OSLog

struct AppClient: Codable, Identifiable {
    let clientId: String
    let clientSecret: String
    let instance: String

    var id: String {
        key
    }

    var key: String {
        return KeychainKeys.client(cleanInstanceHost).key
    }

    private var cleanInstanceHost: String {
        if let components = URLComponents(string: instance),
            let host = components.host
        {
            return host
        } else if let components = URLComponents(string: "https://\(instance)"),
            let host = components.host
        {
            return host
        }
        // If not a valid URL, return as is (might be just a hostname)
        return instance
    }

    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let keychain = KeychainSwift()

        if !keychain.set(data, forKey: key) {
            throw AccountError.keyChainError(
                "Failed to save client credentials")
        }
    }

    func delete() {
        KeychainSwift().delete(key)
    }

    static func retrieve(for instance: String) -> AppClient? {
        let cleanInstance = cleanInstanceHost(from: instance)
        let key = KeychainKeys.client(cleanInstance).key

        guard let data = KeychainSwift().getData(key),
            let client = try? JSONDecoder().decode(AppClient.self, from: data)
        else {
            return nil
        }
        return client
    }

    static func retrieveAll() -> [AppClient] {
        let keychain = KeychainSwift(keyPrefix: KeychainKeys.client(nil).prefix)
        let keys = keychain.allKeys
        return keys.compactMap { key in
            guard let data = keychain.getData(key),
                let client = try? JSONDecoder().decode(
                    AppClient.self, from: data)
            else {
                return nil
            }
            return client
        }
    }

    static func deleteAll() {
        let keychain = KeychainSwift(keyPrefix: KeychainKeys.client(nil).prefix)
        let keys = keychain.allKeys
        for key in keys {
            keychain.delete(key)
        }
    }

    static func register(instance: String) async throws -> AppClient {
        // Check existing client
        if let existingClient = retrieve(for: instance) {
            return existingClient
        }

        // Create new client
        let networkClient = await NetworkClient(instance: instance)
        let endpoint = AppsEndpoints.create

        do {
            let response = try await networkClient.fetch(
                endpoint, type: AppRegistrationResponse.self)

            let client = AppClient(
                clientId: response.clientId,
                clientSecret: response.clientSecret,
                instance: instance
            )

            try client.save()
            return client

        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                throw AccountError.invalidURL
            case .invalidResponse:
                throw AccountError.invalidResponse
            case .httpError(let code):
                throw AccountError.registrationFailed("HTTP error: \(code)")
            case .decodingError(let decodingError):
                throw AccountError.registrationFailed(
                    "Failed to decode response: \(decodingError.localizedDescription)"
                )
            case .networkError(let networkError):
                throw AccountError.registrationFailed(
                    "Network error: \(networkError.localizedDescription)")
            case .unauthorized:
                throw AccountError.registrationFailed("Unauthorized")
            }
        }
    }

    private static func cleanInstanceHost(from instance: String) -> String {
        if let components = URLComponents(string: instance),
            let host = components.host
        {
            return host
        }
        // If not a valid URL, return as is (might be just a hostname)
        return instance
    }
}
