import Foundation

enum UserEndpoints {
    case me
}

extension UserEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .me:
            return "/api/me"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .me:
            return .get
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        return nil
    }
} 