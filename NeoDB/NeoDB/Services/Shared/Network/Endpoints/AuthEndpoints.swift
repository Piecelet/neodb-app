import Foundation

enum AuthEndpoints {
    case register(clientName: String, redirectUri: String, scopes: String)
    case token(code: String, clientId: String, clientSecret: String, redirectUri: String)
}

extension AuthEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .register:
            return "/api/v1/apps"
        case .token:
            return "/oauth/token"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .register, .token:
            return .post
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        switch self {
        case .register(let clientName, let redirectUri, let scopes):
            let parameters: [String: String] = [
                "client_name": clientName,
                "redirect_uris": redirectUri,
                "scopes": scopes
            ]
            return try? JSONSerialization.data(withJSONObject: parameters)
            
        case .token(let code, let clientId, let clientSecret, let redirectUri):
            let parameters: [String: String] = [
                "client_id": clientId,
                "client_secret": clientSecret,
                "code": code,
                "redirect_uri": redirectUri,
                "grant_type": "authorization_code"
            ]
            return parameters
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
                .data(using: .utf8)
        }
    }
    
    var headers: [String: String]? {
        switch self {
        case .register:
            return ["Content-Type": "application/json"]
        case .token:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
} 