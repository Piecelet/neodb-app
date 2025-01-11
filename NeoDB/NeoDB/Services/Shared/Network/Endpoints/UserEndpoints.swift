import Foundation

enum UserEndpoints {
    case fetchProfile
}

extension UserEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .fetchProfile:
            return "/api/user/profile"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        return nil
    }
} 