import Foundation
import OSLog

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case invalidURL
    case unauthorized
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
}

@MainActor
class NetworkClient {
    private let logger = Logger.network
    private let session: URLSession
    private let instance: String
    private var accessToken: String?
    
    init(instance: String, accessToken: String? = nil) {
        self.instance = instance
        self.accessToken = accessToken
        self.session = URLSession.shared
    }
    
    private func makeURL(endpoint: NetworkEndpoint) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = instance
        
        // Handle path construction
        var path = endpoint.path
        if !path.hasPrefix("/oauth") && !path.hasPrefix("/api") {
            path = "/api" + path
        }
        components.path = path
        components.queryItems = endpoint.queryItems
        
        guard let url = components.url else {
            logger.error("Failed to construct URL for endpoint: \(endpoint.path)")
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    private func makeRequest(for endpoint: NetworkEndpoint) throws -> URLRequest {
        let url = try makeURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Handle request body and content type
        if let body = endpoint.body {
            request.setValue(endpoint.bodyContentType?.headerValue, forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }
    
    func fetch<T: Decodable>(_ endpoint: NetworkEndpoint, type: T.Type) async throws -> T {
        let request = try makeRequest(for: endpoint)
        logger.debug("Fetching: \(endpoint.path)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    logger.error("Unauthorized request")
                    throw NetworkError.unauthorized
                }
                logger.error("HTTP error: \(httpResponse.statusCode)")
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                logger.debug("Attempting to decode response data")
                if let dataString = String(data: data, encoding: .utf8) {
                    logger.debug("Raw response: \(dataString)")
                }
                return try decoder.decode(T.self, from: data)
            } catch {
                logger.error("Decoding error: \(error.localizedDescription)")
                if let dataString = String(data: data, encoding: .utf8) {
                    logger.error("Raw response: \(dataString)")
                }
                throw NetworkError.decodingError(error)
            }
        } catch {
            if let networkError = error as? NetworkError {
                throw networkError
            }
            logger.error("Network error: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        }
    }
    
    func send(_ endpoint: NetworkEndpoint) async throws {
        let request = try makeRequest(for: endpoint)
        logger.debug("Sending request to: \(endpoint.path)")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            }
            logger.error("HTTP error: \(httpResponse.statusCode)")
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
} 
