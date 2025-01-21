import Foundation

enum AppConfig {
    static let baseURL = "https://neodb.social"
    
    static let defaultInstance = "neodb.social"
    
    static let defaultItemCoverRatio: CGFloat = 3 / 4
    
    enum OAuth {
        static let redirectUri = "neodb://oauth/callback"
        static let scopes = "read write"
    }
} 
