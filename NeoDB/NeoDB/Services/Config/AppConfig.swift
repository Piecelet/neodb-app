import Foundation

enum AppConfig {
    static let baseURL = "https://neodb.social"
    
    enum OAuth {
        // These values need to be updated with the ones from NeoDB after registering the app
        static let clientId = "YOUR_CLIENT_ID"
        static let clientSecret = "YOUR_CLIENT_SECRET"
        static let redirectUri = "neodb://oauth/callback"
        static let scopes = "read write"
    }
} 
