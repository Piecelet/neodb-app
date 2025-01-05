import Foundation

@MainActor
class UserService {
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func getCurrentUser() async throws -> User {
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
        
        return try JSONDecoder().decode(User.self, from: data)
    }
} 