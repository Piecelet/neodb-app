import Foundation

enum AuthEndpoints {
    case authorize(clientId: String, redirectUri: String, scope: String)
    case token(code: String, clientId: String, clientSecret: String, redirectUri: String)
    case revokeToken(token: String)
}

extension AuthEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .authorize:
            return "/oauth/authorize"
        case .token:
            return "/oauth/token"
        case .revokeToken:
            return "/oauth/revoke"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .authorize:
            return .get
        case .token, .revokeToken:
            return .post
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .authorize(let clientId, let redirectUri, let scope):
            return [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectUri),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: scope)
            ]
        default:
            return nil
        }
    }
    
    var body: Data? {
        switch self {
        case .token(let code, let clientId, let clientSecret, let redirectUri):
            let params = [
                "grant_type": "authorization_code",
                "code": code,
                "client_id": clientId,
                "client_secret": clientSecret,
                "redirect_uri": redirectUri
            ]
            return try? JSONSerialization.data(withJSONObject: params)
            
        case .revokeToken(let token):
            let params = ["token": token]
            return try? JSONSerialization.data(withJSONObject: params)
            
        default:
            return nil
        }
    }
} 