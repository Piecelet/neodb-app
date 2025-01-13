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
    private static let logger = Logger.managers.client
    let id: String
    let name: String
    let website: URL?
    let redirectUri: String
    let clientId: String
    let clientSecret: String
    let vapidKey: String
    let instance: String

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

    init(response: AppsResponse, instance: String) {
        self.id = response.id
        self.name = response.name
        self.website = response.website
        self.redirectUri = response.redirectUri
        self.clientId = response.clientId
        self.clientSecret = response.clientSecret
        self.vapidKey = response.vapidKey
        self.instance = instance
    }

    func save() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let keychain = KeychainSwift()

        if !keychain.set(data, forKey: key) {
            Self.logger.error(
                "Failed to save client credentials for instance: \(instance)")
            throw AccountError.keyChainError(
                "Failed to save client credentials")
        }
        Self.logger.debug("Saved client credentials for instance: \(instance)")
    }

    func delete() {
        KeychainSwift().delete(key)
        Self.logger.debug(
            "Deleted client credentials for instance: \(instance)")
    }

    static func retrieve(for instance: String) -> AppClient? {
        let cleanInstance = cleanInstanceHost(from: instance)
        let key = KeychainKeys.client(cleanInstance).key

        guard let data = KeychainSwift().getData(key),
            let client = try? JSONDecoder().decode(AppClient.self, from: data)
        else {
            logger.debug(
                "No client credentials found for instance: \(instance)")
            return nil
        }
        logger.debug("Retrieved client credentials for instance: \(instance)")
        return client
    }

    static func retrieveAll() -> [AppClient] {
        let keychain = KeychainSwift(keyPrefix: KeychainKeys.client(nil).prefix)
        let keys = keychain.allKeys
        let clients = keys.compactMap { (key: String) -> AppClient? in
            guard let data = keychain.getData(key),
                let client = try? JSONDecoder().decode(
                    AppClient.self, from: data)
            else {
                return nil
            }
            return client
        }
        logger.debug("Retrieved \(clients.count) client(s)")
        return clients
    }

    static func deleteAll() {
        let keychain = KeychainSwift(keyPrefix: KeychainKeys.client(nil).prefix)
        let keys = keychain.allKeys
        for key in keys {
            keychain.delete(key)
        }
        logger.debug("Deleted all client credentials")
    }

    static func register(instance: String) async throws -> AppClient {
        // Check existing client
        if let existingClient = retrieve(for: instance) {
            logger.debug(
                "Using existing client credentials for instance: \(instance)")
            return existingClient
        }

        logger.debug("Registering new client for instance: \(instance)")
        // Create new client
        let networkClient = await NetworkClient(instance: instance)
        let endpoint = AppsEndpoints.create

        do {
            let response = try await networkClient.fetch(
                endpoint, type: AppsResponse.self)

            let client = AppClient(
                response: response,
                instance: instance
            )

            try client.save()
            logger.debug(
                "Successfully registered new client for instance: \(instance)")
            return client

        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                logger.error("Invalid URL for instance: \(instance)")
                throw AccountError.invalidURL
            case .invalidResponse:
                logger.error("Invalid response from instance: \(instance)")
                throw AccountError.invalidResponse
            case .httpError(let code):
                logger.error("HTTP error \(code) from instance: \(instance)")
                throw AccountError.registrationFailed("HTTP error: \(code)")
            case .decodingError(let decodingError):
                logger.error(
                    "Failed to decode response from instance: \(instance), error: \(decodingError.localizedDescription)"
                )
                throw AccountError.registrationFailed(
                    "Failed to decode response: \(decodingError.localizedDescription)"
                )
            case .networkError(let networkError):
                logger.error(
                    "Network error for instance: \(instance), error: \(networkError.localizedDescription)"
                )
                throw AccountError.registrationFailed(
                    "Network error: \(networkError.localizedDescription)")
            case .unauthorized:
                logger.error("Unauthorized request for instance: \(instance)")
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
