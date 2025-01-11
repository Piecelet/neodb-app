//
//  TimelineService.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Foundation
import OSLog

@MainActor
class TimelineService {
    private let authService: AuthService
    private let decoder: JSONDecoder
    private let logger = Logger.networkTimeline
    
    init(authService: AuthService) {
        self.authService = authService
        
        self.decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to basic ISO8601 without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected date string to be ISO8601-formatted.")
        }
    }
    
    func getTimeline(maxId: String? = nil, sinceId: String? = nil, minId: String? = nil, limit: Int = 20, local: Bool = true) async throws -> [Status] {
        guard let accessToken = authService.accessToken else {
            logger.error("No access token available")
            throw AuthError.unauthorized
        }
        
        let baseURL = "https://\(authService.currentInstance)"
        var components = URLComponents(string: "\(baseURL)/api/v1/timelines/public")!
        
        var queryItems = [URLQueryItem]()
        // Always add local=true to show only local statuses
        queryItems.append(URLQueryItem(name: "local", value: String(local)))
        
        if let maxId = maxId {
            queryItems.append(URLQueryItem(name: "max_id", value: maxId))
        }
        if let sinceId = sinceId {
            queryItems.append(URLQueryItem(name: "since_id", value: sinceId))
        }
        if let minId = minId {
            queryItems.append(URLQueryItem(name: "min_id", value: minId))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(min(limit, 40))))
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        logger.debug("Fetching timeline from: \(components.url?.absoluteString ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw AuthError.invalidResponse
        }
        
        logger.debug("Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized access")
                throw AuthError.unauthorized
            }
            logger.error("Invalid response status: \(httpResponse.statusCode)")
            
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                logger.error("Server error: \(errorMessage)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Response body: \(responseString)")
            }
            
            throw AuthError.invalidResponse
        }
        
        do {
            let statuses = try decoder.decode([Status].self, from: data)
            logger.debug("Successfully decoded \(statuses.count) local statuses")
            return statuses
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    logger.error("Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    logger.error("Key not found: \(key.stringValue) in \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    logger.error("Type mismatch: expected \(type) at \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    logger.error("Value not found: expected \(type) at \(context.debugDescription)")
                @unknown default:
                    logger.error("Unknown decoding error: \(decodingError)")
                }
            }
            if let responseString = String(data: data, encoding: .utf8) {
                logger.error("Raw response: \(responseString)")
            }
            throw error
        }
    }
} 