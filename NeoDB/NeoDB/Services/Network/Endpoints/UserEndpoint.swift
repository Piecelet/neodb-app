import Foundation

enum UserEndpoint {
    case me
}

extension UserEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .me:
            return "/me"
        }
    }
}
