import Foundation

enum AppConfig {
    static let baseURL = "https://neodb.social"
    
    static let defaultInstance = "neodb.social"
    
    static let defaultItemCoverRatio: CGFloat = 3 / 4
    
    static let wishkitApiKey = "6AA7DB14-8EED-4895-B4D6-3F6EB5210921"
    
    enum OAuth {
        static let redirectUri = "neodb://oauth/callback"
        static let scopes = "read write follow push"
        static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Mobile/15E148 Safari/604.1"
    }
    
    enum PublicInfo {
        static let name = "Piecelet for NeoDB"
        static let website = "https://github.com/lcandy2/neodb-app"
    }
}
