import Foundation
import OSLog

@MainActor
class UserService {
    private let accountsManager: AppAccountsManager
    private let cache = NSCache<NSString, CachedUser>()
    private let cacheKey = "cached_user"
    private let logger = Logger.networkUser
    
    init(accountsManager: AppAccountsManager) {
        self.accountsManager = accountsManager
    }
    
    func getCurrentUser(forceRefresh: Bool = false) async throws -> User {
        let cacheKey = "\(accountsManager.currentAccount.instance)_\(cacheKey)" as NSString
        
        // Return cached user if available and not forcing refresh
        if !forceRefresh, let cachedUser = cache.object(forKey: cacheKey) {
            logger.debug("Returning cached user for instance: \(accountsManager.currentAccount.instance)")
            return cachedUser.user
        }
        
        guard accountsManager.isAuthenticated else {
            logger.error("No access token available")
            throw NetworkError.unauthorized
        }
        
        logger.debug("Fetching user profile from network")
        let user = try await accountsManager.currentClient.fetch(UserEndpoints.me, type: User.self)
        
        // Cache the user
        cache.setObject(CachedUser(user: user), forKey: cacheKey)
        logger.debug("Cached user profile for instance: \(accountsManager.currentAccount.instance)")
        
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
