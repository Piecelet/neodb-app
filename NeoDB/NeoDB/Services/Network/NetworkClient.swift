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
    case cancelled
}

@MainActor
class NetworkClient {
    /// Debug flag to control logging of network requests and responses
    private static let isDebugRequestEnabled: Bool = true
    private static let isDebugResponseEnabled: Bool = false
    
    private let logger = Logger.network
    private let urlSession: URLSession
    private let instance: String
    private var oauthToken: OauthToken?
    private let decoder: JSONDecoder = JSONDecoder()
    private let encoder: JSONEncoder = JSONEncoder()
    private let webSocketTask: URLSessionWebSocketTask?
    private(set) var lastResponse: HTTPURLResponse?

    init(instance: String, oauthToken: OauthToken? = nil) {
        self.instance = instance
        self.oauthToken = oauthToken
        self.urlSession = URLSession.shared
        self.webSocketTask = nil
        
        // Configure decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    private func makeURL(scheme: String = "https", endpoint: NetworkEndpoint) throws -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = instance

        switch endpoint.host {
        case .currentInstance:
            components.host = instance
        case .custom(let host):
            components.host = host
        }

        // Handle path construction
        var path = endpoint.path
        switch endpoint.type {
        case .apiV1:
            path = "/api/v1" + path
        case .apiV2:
            path = "/api/v2" + path
        case .api:
            path = "/api" + path
        case .oauth:
            path = "/oauth" + path
        case .raw:
            break
        }
        components.path = path
        
        // Filter out nil query items and only set if there are valid items
        if let queryItems = endpoint.queryItems?.compactMap({ item in
            item.value.map { URLQueryItem(name: item.name, value: $0) }
        }), !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            logger.error("Failed to construct URL for endpoint: \(endpoint.path)")
            throw NetworkError.invalidURL
        }

        return url
    }

    private func makeRequest(for endpoint: NetworkEndpoint) throws -> URLRequest
    {
        let url = try makeURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Handle request body and content type
        if let body = endpoint.body, let bodyContentType = endpoint.bodyContentType, bodyContentType == .json {
            request.setValue(
                bodyContentType.headerValue,
                forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let token = oauthToken?.accessToken {
            request.setValue(
                "Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func setOauthToken(_ token: OauthToken?) {
        self.oauthToken = token
    }

    func fetch<T: Decodable>(_ endpoint: NetworkEndpoint, type: T.Type)
        async throws -> T
    {
        let request = try makeRequest(for: endpoint)
        logRequest(request)

        do {
            let (data, response) = try await urlSession.data(for: request)
            logResponse(response, data: data)

            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.invalidResponse
            }

            lastResponse = httpResponse  // Store the response

            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("HTTP error: \(httpResponse.statusCode)")
                throw NetworkError.httpError(httpResponse.statusCode)
            }

            logger.debug("Attempting to decode response data")
            if  T.self == HTMLPage.self {
                logger.debug("Processing HTML response")
                guard let htmlString = String(data: data, encoding: .utf8) else {
                    logger.error("Failed to decode HTML string from data")
                    throw NetworkError.decodingError(NSError(domain: "", code: -1))
                }
                logger.debug("Successfully decoded HTML string, length: \(htmlString.count)")
                logger.debug("Creating HTMLPage instance")
                return HTMLPage(stringValue: htmlString) as! T
            }

            logger.debug("Attempting to decode JSON response for type: \(String(describing: T.self))")
            do {
                let result = try decoder.decode(type, from: data)
                return result
            } catch {
                logDecodingError(error, data: data)
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            if error.code == .cancelled {
                logger.debug("Request cancelled")
                throw NetworkError.cancelled
            }
            logger.error("Network error: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw NetworkError.networkError(error)
        }
    }

    func send(_ endpoint: NetworkEndpoint) async throws {
        let request = try makeRequest(for: endpoint)
        logger.debug("Sending request to: \(endpoint.path)")

        let (_, response) = try await urlSession.data(for: request)

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

    func makeWebSocketTask(endpoint: NetworkEndpoint) throws -> URLSessionWebSocketTask {
        let url = try makeURL(scheme: "wss", endpoint: endpoint)
        var request = URLRequest(url: url)
        
        // Add authorization if available
        if let token = oauthToken?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add any additional headers from the endpoint
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        logger.debug("Creating WebSocket connection to: \(url.absoluteString)")
        return urlSession.webSocketTask(with: request)
    }

    // MARK: - Debug Logging
    
    private func logRequest(_ request: URLRequest) {
        if !Self.isDebugRequestEnabled { return }
        let loggerRequest = Logger.networkRequest
        
        loggerRequest.debug("🌐 REQUEST [\(request.httpMethod ?? "Unknown")] \(request.url?.absoluteString ?? "")")
        
        if let headers = request.allHTTPHeaderFields {
            loggerRequest.debug("Headers: \(headers)")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            loggerRequest.debug("Body: \(bodyString)")
        }
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        if !Self.isDebugResponseEnabled { return }
        let loggerResponse = Logger.networkResponse
        
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        loggerResponse.debug("📥 RESPONSE [\(httpResponse.statusCode)] \(httpResponse.url?.absoluteString ?? "")")
        
        if let headers = httpResponse.allHeaderFields as? [String: String] {
            loggerResponse.debug("Headers: \(headers)")
        }
        
        if let bodyString = String(data: data, encoding: .utf8) {
            loggerResponse.debug("Body: \(bodyString)")
        }
    }

    private func logDecodingError(_ error: Error, data: Data) {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                logger.error("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                logger.error("Key not found: \(key.stringValue) - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                logger.error("Type mismatch: \(type) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                logger.error("Value not found: \(type) - \(context.debugDescription)")
            @unknown default:
                logger.error("Unknown decoding error: \(decodingError)")
            }
        }
        
        if let rawResponse = String(data: data, encoding: .utf8) {
            logger.error("Raw response: \(rawResponse)")
        }
    }
}

// MARK: - URLRequest Extension
private extension URLRequest {
    var allHTTPHeaders: [String: String]? {
        allHTTPHeaderFields?.reduce(into: [String: String]()) { result, header in
            // 敏感信息处理
            if header.key.lowercased() == "authorization" {
                result[header.key] = "Bearer [REDACTED]"
            } else {
                result[header.key] = header.value
            }
        }
    }
}
