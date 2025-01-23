//
//  JoinMastodonClient.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation
import OSLog

@MainActor
class JoinMastodonClient {
    private let logger = Logger.client.joinMastodon
    private let endpoint = "https://api.joinmastodon.org/servers"
    
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    
    init() {
        self.urlSession = .shared
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func fetchServers() async -> [JoinMastodonServers] {
        guard let url = URL(string: endpoint) else {
            logger.error("Invalid URL: \(endpoint)")
            return []
        }
        
        do {
            let (data, response) = try await urlSession.data(for: URLRequest(url: url))
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                return []
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("HTTP error: \(httpResponse.statusCode)")
                return []
            }
            
            return try decoder.decode([JoinMastodonServers].self, from: data)
            
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            return []
        }
    }
}

