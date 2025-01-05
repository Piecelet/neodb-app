import Foundation

@MainActor
class UserService {
    private let authService: AuthService
    private let cache = NSCache<NSString, CachedUser>()
    private let cacheKey = "cached_user"
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func getCurrentUser(forceRefresh: Bool = false) async throws -> User {
        let cacheKey = "\(authService.currentInstance)_\(cacheKey)" as NSString
        
        // Return cached user if available and not forcing refresh
        if !forceRefresh, let cachedUser = cache.object(forKey: cacheKey) {
            return cachedUser.user
        }
        
        guard let accessToken = authService.accessToken else {
            throw AuthError.unauthorized
        }
        
        let baseURL = "https://\(authService.currentInstance)"
        guard let url = URL(string: "\(baseURL)/api/me") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw AuthError.unauthorized
            }
            throw AuthError.invalidResponse
        }
        
        let user = try JSONDecoder().decode(User.self, from: data)
        
        // Cache the user
        cache.setObject(CachedUser(user: user), forKey: cacheKey)
        
        return user
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// Helper class to make User cacheable
final class CachedUser {
    let user: User
    
    init(user: User) {
        self.user = user
    }
} 