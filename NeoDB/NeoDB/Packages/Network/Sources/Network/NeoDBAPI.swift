import Foundation

public enum NeoDBAPIEndpoint {
    case createApplication
    case authorize
    case token
    case me
    
    func path(baseURL: URL) -> URL {
        switch self {
        case .createApplication:
            return baseURL.appendingPathComponent("api/v1/apps")
        case .authorize:
            return baseURL.appendingPathComponent("oauth/authorize")
        case .token:
            return baseURL.appendingPathComponent("oauth/token")
        case .me:
            return baseURL.appendingPathComponent("api/me")
        }
    }
}

public struct NeoDBApplication: Codable {
    public let clientId: String
    public let clientSecret: String
    public let name: String
    public let redirectUri: String
    public let vapidKey: String?
    public let website: String?
    
    private enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case name
        case redirectUri = "redirect_uri"
        case vapidKey = "vapid_key"
        case website
    }
}

public struct NeoDBAccessToken: Codable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}

public struct NeoDBUser: Codable {
    public let url: String
    public let externalAcct: String
    public let displayName: String
    public let avatar: String
    
    private enum CodingKeys: String, CodingKey {
        case url
        case externalAcct = "external_acct"
        case displayName = "display_name"
        case avatar
    }
}

public enum NeoDBAPIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unknown
}

public class NeoDBAPI {
    private let baseURL: URL
    private let session: URLSession
    
    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    public func createApplication(
        clientName: String,
        redirectURI: String,
        website: String? = nil
    ) async throws -> NeoDBApplication {
        var components = URLComponents(url: NeoDBAPIEndpoint.createApplication.path(baseURL: baseURL), resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "client_name", value: clientName),
            URLQueryItem(name: "redirect_uris", value: redirectURI)
        ]
        if let website = website {
            components?.queryItems?.append(URLQueryItem(name: "website", value: website))
        }
        
        guard let url = components?.url else {
            throw NeoDBAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NeoDBAPIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NeoDBAPIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(NeoDBApplication.self, from: data)
    }
    
    public func getAuthorizationURL(
        clientId: String,
        redirectURI: String,
        scope: String = "read write"
    ) -> URL? {
        var components = URLComponents(url: NeoDBAPIEndpoint.authorize.path(baseURL: baseURL), resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scope)
        ]
        return components?.url
    }
    
    public func exchangeCodeForToken(
        clientId: String,
        clientSecret: String,
        code: String,
        redirectURI: String
    ) async throws -> NeoDBAccessToken {
        let url = NeoDBAPIEndpoint.token.path(baseURL: baseURL)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        
        let body = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NeoDBAPIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NeoDBAPIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(NeoDBAccessToken.self, from: data)
    }
    
    public func getCurrentUser(accessToken: String) async throws -> NeoDBUser {
        let url = NeoDBAPIEndpoint.me.path(baseURL: baseURL)
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NeoDBAPIError.unknown
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NeoDBAPIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(NeoDBUser.self, from: data)
    }
} 