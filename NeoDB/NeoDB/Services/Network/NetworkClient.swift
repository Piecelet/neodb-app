import Foundation
import OSLog
import Perception

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case invalidResponse
    case httpError(code: Int, message: String? = nil)
    case decodingError(Error)
    case messageError(String)
    case networkError(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Unauthorized"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code, let message):
            if let message = message {
                return "HTTP \(code): \(message)"
            }
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cancelled:
            return "Request cancelled"
        case .messageError(let message):
            return message
        }
    }
    
    var failureReason: String? {
        switch self {
        case .decodingError(let error):
            return error.localizedDescription
        case .networkError(let error):
            return error.localizedDescription
        case .httpError(let code, let message):
            if let message = message {
                return "Server returned error: \(message)"
            }
            return "Server returned status code: \(code)"
        case .messageError(let message):
            return "Server returned error: \(message)"
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please check the URL is correct"
        case .unauthorized:
            return "Please try logging in again"
        case .httpError(let code, _):
            if code == 404 {
                return "The requested resource was not found"
            } else if code >= 500 {
                return "Please try again later"
            }
            return nil
        default:
            return nil
        }
    }
}

// 可以参考 IceCubes 中的做法，利用 OSAllocatedUnfairLock<Critical>
// 来集中管理可变状态，让整个类可以在多线程环境下既保持高并发性能，又避免数据竞争。
// 此处同样通过 @unchecked Sendable 保证编译器不会阻止在并发上下文中使用 NetworkClient，
// 但使用者仍需确保内部的线程安全操作正确。
@Perceptible final class NetworkClient: @unchecked Sendable {

    // 在这里按照 IceCubes 的思路，把所有的可变状态都放进 Critical 结构体里，通过锁访问。
    // 这样做可以让你在高并发场景下仍然保持良好的性能和线程安全。
    private let critical: OSAllocatedUnfairLock<Critical>

    private struct Critical: Sendable {
        var oauthToken: OauthToken?
        var lastResponse: HTTPURLResponse?
    }

    private let logger = Logger.network
    private let urlSession: URLSession
    private let instance: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // 为了演示保留 WebSocketTask 等操作，或者你可以像 IceCubes 一样将其提取到其他方法
    // 并通过锁管理数据等。
    private let webSocketTask: URLSessionWebSocketTask?

    // Debug 标志控制
    private static let isDebugRequestEnabled: Bool = true
    private static let isDebugResponseEnabled: Bool = false

    // 如果需要给外部读取或设定 Token，最好写成对锁的 get/set
    var currentToken: OauthToken? {
        get {
            critical.withLock { $0.oauthToken }
        }
        set {
            critical.withLock { $0.oauthToken = newValue }
        }
    }

    var lastResponse: HTTPURLResponse? {
        get {
            critical.withLock { $0.lastResponse }
        }
        set {
            critical.withLock { $0.lastResponse = newValue }
        }
    }

    init(instance: String, oauthToken: OauthToken? = nil) {
        self.instance = instance
        self.urlSession = URLSession.shared
        self.webSocketTask = nil

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder

        // 和 IceCubes 类似，初始化锁并设置初始状态
        critical = .init(
            initialState: Critical(oauthToken: oauthToken, lastResponse: nil))
    }

    // 参照 IceCubes Client 中的思路，封装出类似的 makeURL 用法
    func makeURL(scheme: String = "https", endpoint: NetworkEndpoint) throws
        -> URL
    {
        var components = URLComponents()
        components.scheme = scheme
        components.host = instance

        switch endpoint.host {
        case .currentInstance:
            components.host = instance
        case .custom(let host):
            components.host = host
        }

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

        if let queryItems = endpoint.queryItems?.compactMap({ item in
            item.value.map { URLQueryItem(name: item.name, value: $0) }
        }), !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            logger.error(
                "Failed to construct URL for endpoint: \(endpoint.path)")
            throw NetworkError.invalidURL
        }

        guard url.host?.contains("piecelet.internal") == false else {
            logger.info("Not requesting internal URL: \(url.absoluteString)")
            throw NetworkError.invalidURL
        }
        return url
    }

    // 参考 IceCubes 做法生成 URLRequest
    private func makeRequest(for endpoint: NetworkEndpoint) throws -> URLRequest
    {
        let url = try makeURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let bodyJson = endpoint.bodyJson {
            request.setValue(
                ContentType.json.headerValue, forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = try encoder.encode(bodyJson)
        } else if let bodyUrlEncoded = endpoint.bodyUrlEncoded {
            request.setValue(
                ContentType.urlEncoded.headerValue,
                forHTTPHeaderField: "Content-Type")
            let items = bodyUrlEncoded.compactMap { item in
                item.value.map { URLQueryItem(name: item.name, value: $0) }
            }
            if !items.isEmpty {
                request.httpBody = items.map { "\($0.name)=\($0.value ?? "")" }
                    .joined(separator: "&")
                    .data(using: .utf8)
            }
        }

        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // request.setValue("Piecelet/\(AppInfo.bundle.version)", forHTTPHeaderField: "User-Agent")

        // 通过锁安全读取当前 oauthToken
        if let token = critical.withLock({ $0.oauthToken?.accessToken }) {
            request.setValue(
                "Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // 通用的抓取数据方法，与 IceCubes 中的做法相似
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

            // 通过锁安全地更新内部状态
            critical.withLock { $0.lastResponse = httpResponse }

            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("HTTP error: \(httpResponse.statusCode)")
                
                // Try to decode error message for HTTP errors
                do {
                    logger.debug("Attempting to decode error message for HTTP \(httpResponse.statusCode)")
                    let messageResult = try decoder.decode(MessageSchema.self, from: data)
                    logger.error("Received error message from server: \(messageResult.message)")
                    throw NetworkError.httpError(code: httpResponse.statusCode, message: messageResult.message)
                } catch let messageError as NetworkError {
                    throw messageError
                } catch {
                    logger.error("Failed to decode error message, using default HTTP error")
                    throw NetworkError.httpError(code: httpResponse.statusCode, message: nil)
                }
            }

            // 如果像 IceCubes 一样需要某些特殊类型（如 HTMLPage），可以保留此处逻辑
            if T.self == HTMLPage.self {
                guard let htmlString = String(data: data, encoding: .utf8)
                else {
                    logger.error("Failed to decode HTML string from data")
                    throw NetworkError.decodingError(
                        NSError(domain: "", code: -1))
                }
                return HTMLPage(stringValue: htmlString) as! T
            }

            do {
                let result = try decoder.decode(type, from: data)
                return result
            } catch let decodingError {
                logDecodingError(decodingError, endpoint: endpoint, data: data, type: type)
                logger.error("First decoding attempt failed for type \(T.self): \(decodingError.localizedDescription)")
                
                // Try to decode as MessageSchema
                do {
                    logger.debug("Attempting to decode as MessageSchema")
                    let messageResult = try decoder.decode(MessageSchema.self, from: data)
                    logger.error("Received error message from server: \(messageResult.message)")
                    throw NetworkError.messageError(messageResult.message)
                } catch let messageError {
                    if messageError is NetworkError {
                        throw messageError
                    }
                    // If MessageSchema decoding also fails, log and throw the original error
                    logger.error("MessageSchema decoding also failed: \(messageError.localizedDescription)")
                    logger.error("Falling back to original decoding error")
                    throw NetworkError.decodingError(decodingError)
                }
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

    // 发送普通请求，不需要返回值，只要判断 HTTP 状态即可
    func send(_ endpoint: NetworkEndpoint) async throws {
        let request = try makeRequest(for: endpoint)
        logger.debug("Sending request to: \(endpoint.path)")
        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw NetworkError.invalidResponse
        }

        critical.withLock { $0.lastResponse = httpResponse }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw NetworkError.unauthorized
            }
            logger.error("HTTP error: \(httpResponse.statusCode)")
            throw NetworkError.httpError(code: httpResponse.statusCode, message: nil)
        }
    }

    // 根据 IceCubes 的思路，使用 wss 协议生成 WebSocketTask，若想通过锁安全记录一些连接状态，
    // 也可将相关字段放进 Critical 内管理。
    func makeWebSocketTask(endpoint: NetworkEndpoint) throws
        -> URLSessionWebSocketTask
    {
        let url = try makeURL(scheme: "wss", endpoint: endpoint)
        var request = URLRequest(url: url)

        if let token = critical.withLock({ $0.oauthToken?.accessToken }) {
            request.setValue(
                "Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        logger.debug("Creating WebSocket connection to: \(url.absoluteString)")
        return urlSession.webSocketTask(with: request)
    }

    // Debug 日志输出，可以根据自己的需求直接复用 IceCubes 中更通用的方式
    private func logRequest(_ request: URLRequest) {
        if !Self.isDebugRequestEnabled { return }
        let loggerRequest = Logger.networkRequest
        loggerRequest.debug(
            "🌐 REQUEST [\(request.httpMethod ?? "Unknown")] \(request.url?.absoluteString ?? "")"
        )
        if let headers = request.allHTTPHeaderFields {
            loggerRequest.debug("Headers: \(headers)")
        }
        if let body = request.httpBody,
            let bodyString = String(data: body, encoding: .utf8)
        {
            loggerRequest.debug("Body: \(bodyString)")
        }
    }

    private func logResponse(_ response: URLResponse, data: Data) {
        if !Self.isDebugResponseEnabled { return }
        let loggerResponse = Logger.networkResponse
        guard let httpResponse = response as? HTTPURLResponse else { return }
        loggerResponse.debug(
            "📥 RESPONSE [\(httpResponse.statusCode)] \(httpResponse.url?.absoluteString ?? "")"
        )
        if let headers = httpResponse.allHeaderFields as? [String: String] {
            loggerResponse.debug("Headers: \(headers)")
        }
        if let bodyString = String(data: data, encoding: .utf8) {
            loggerResponse.debug("Body: \(bodyString)")
        }
    }

    private func logDecodingError<T>(
        _ error: Error,
        endpoint: NetworkEndpoint,
        data: Data,
        type: T.Type
    ) {
        logger.error("""
            Decoding error for \(String(describing: type))
            Endpoint: \(endpoint.path)
            Error: \(error.localizedDescription)
            Raw Data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")
            Debug Description: \(error)
            """)
        
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                logger.error("Coding path: \(context.codingPath.map { $0.stringValue })")
            case .valueNotFound(let type, let context):
                logger.error("Value of type '\(type)' not found: \(context.debugDescription)")
                logger.error("Coding path: \(context.codingPath.map { $0.stringValue })")
            case .typeMismatch(let type, let context):
                logger.error("Type '\(type)' mismatch: \(context.debugDescription)")
                logger.error("Coding path: \(context.codingPath.map { $0.stringValue })")
            case .dataCorrupted(let context):
                logger.error("Data corrupted: \(context.debugDescription)")
                logger.error("Coding path: \(context.codingPath.map { $0.stringValue })")
            @unknown default:
                logger.error("Unknown decoding error: \(decodingError)")
            }
        }
    }
}

// 扩展以在调试输出中安全地隐藏敏感信息
extension URLRequest {
    fileprivate var allHTTPHeaderFieldsSafe: [String: String]? {
        allHTTPHeaderFields?.reduce(into: [String: String]()) {
            result, header in
            if header.key.lowercased() == "authorization" {
                result[header.key] = "Bearer [REDACTED]"
            } else {
                result[header.key] = header.value
            }
        }
    }
}
