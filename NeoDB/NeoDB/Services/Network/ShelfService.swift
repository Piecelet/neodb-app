import Foundation
import OSLog

@MainActor
class ShelfService {
    private let authService: AuthService
    private let logger = Logger(subsystem: "social.neodb.app", category: "ShelfService")
    private let decoder: JSONDecoder
    
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
    
    func getShelfItems(type: ShelfType, category: ItemCategory? = nil, page: Int = 1) async throws -> PagedMarkSchema {
        guard let accessToken = authService.accessToken else {
            logger.error("No access token available")
            throw AuthError.unauthorized
        }
        
        let baseURL = "https://\(authService.currentInstance)"
        var components = URLComponents(string: "\(baseURL)/api/me/shelf/\(type.rawValue)")!
        
        var queryItems = [URLQueryItem]()
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        logger.debug("Fetching shelf items from: \(components.url?.absoluteString ?? "")")
        
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
            let pagedMarks = try decoder.decode(PagedMarkSchema.self, from: data)
            logger.debug("Successfully decoded \(pagedMarks.data.count) marks")
            return pagedMarks
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