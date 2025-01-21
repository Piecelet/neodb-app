import Foundation

enum AppConfig {
    static let baseURL = "https://neodb.social"
    
    static let defaultInstance = "neodb.social"
    
    static let defaultItemCoverRatio: CGFloat = 3 / 4
    
    static let wishkitApiKey = "6AA7DB14-8EED-4895-B4D6-3F6EB5210921"
    
    enum OAuth {
        static let redirectUri = "neodb://oauth/callback"
        static let scopes = "read write"
    }
} 
