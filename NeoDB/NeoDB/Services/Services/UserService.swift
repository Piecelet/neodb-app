import Foundation
import OSLog

@MainActor
class UserService {
    private let authService: AuthService
    private let networkClient: NetworkClient
    private let cache = NSCache<NSString, CachedUser>()
    private let cacheKey = "cached_user"
    private let logger = Logger.networkUser
    
    init(authService: AuthService) {
        self.authService = authService
        self.networkClient = NetworkClient(instance: authService.currentInstance, accessToken: authService.accessToken)
    }
    
    func getCurrentUser(forceRefresh: Bool = false) async throws -> User {
        let cacheKey = "\(authService.currentInstance)_\(cacheKey)" as NSString
        
        // Return cached user if available and not forcing refresh
        if !forceRefresh, let cachedUser = cache.object(forKey: cacheKey) {
            logger.debug("Returning cached user for instance: \(authService.currentInstance)")
            return cachedUser.user
        }
        
        guard authService.accessToken != nil else {
            logger.error("No access token available")
            throw NetworkError.unauthorized
        }
        
        logger.debug("Fetching user profile from network")
        let user = try await networkClient.fetch(UserEndpoints.me, type: User.self)
        
        // Cache the user
        cache.setObject(CachedUser(user: user), forKey: cacheKey)
        logger.debug("Cached user profile for instance: \(authService.currentInstance)")
        
        return user
    }
    
    func clearCache() {
        cache.removeAllObjects()
        logger.debug("Cleared user cache")
    }
}

// Helper class to make User cacheable
final class CachedUser {
    let user: User
    
    init(user: User) {
        self.user = user
    }
} 
