import Foundation
import OSLog

protocol NetworkEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

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
    private let baseURL: String
    private var accessToken: String?
    
    init(baseURL: String, accessToken: String? = nil) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.session = URLSession.shared
    }
    
    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }
    
    func fetch<T: Decodable>(_ endpoint: NetworkEndpoint, type: T.Type) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            logger.error("Invalid URL: \(baseURL)\(endpoint.path)")
            throw NetworkError.invalidURL
        }
        
        if let queryItems = endpoint.queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
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
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                logger.error("Decoding error: \(error.localizedDescription)")
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
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            logger.error("Invalid URL: \(baseURL)\(endpoint.path)")
            throw NetworkError.invalidURL
        }
        
        if let queryItems = endpoint.queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
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