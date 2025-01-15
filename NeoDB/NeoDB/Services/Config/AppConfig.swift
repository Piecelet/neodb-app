import Foundation

enum AppConfig {
    static let baseURL = "https://neodb.social"
    
    static let defaultInstance = "neodb.social"
    
    enum OAuth {
        static let redirectUri = "neodb://oauth/callback"
        static let scopes = "read write"
    }
} 
