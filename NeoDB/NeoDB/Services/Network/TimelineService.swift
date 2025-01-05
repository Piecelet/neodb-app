import Foundation

@MainActor
class TimelineService {
    private let authService: AuthService
    private let decoder: JSONDecoder
    
    init(authService: AuthService) {
        self.authService = authService
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func getHomeTimeline(maxId: String? = nil, sinceId: String? = nil, minId: String? = nil, limit: Int = 20) async throws -> [Status] {
        guard let accessToken = authService.accessToken else {
            throw AuthError.unauthorized
        }
        
        let baseURL = "https://\(authService.currentInstance)"
        var components = URLComponents(string: "\(baseURL)/api/v1/timelines/home")!
        
        var queryItems = [URLQueryItem]()
        if let maxId = maxId {
            queryItems.append(URLQueryItem(name: "max_id", value: maxId))
        }
        if let sinceId = sinceId {
            queryItems.append(URLQueryItem(name: "since_id", value: sinceId))
        }
        if let minId = minId {
            queryItems.append(URLQueryItem(name: "min_id", value: minId))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(min(limit, 40))))
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
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
        
        return try decoder.decode([Status].self, from: data)
    }
    
    func getPublicTimeline(local: Bool = false, remote: Bool = false, onlyMedia: Bool = false, maxId: String? = nil, sinceId: String? = nil, minId: String? = nil, limit: Int = 20) async throws -> [Status] {
        let baseURL = "https://\(authService.currentInstance)"
        var components = URLComponents(string: "\(baseURL)/api/v1/timelines/public")!
        
        var queryItems = [URLQueryItem]()
        if local {
            queryItems.append(URLQueryItem(name: "local", value: "true"))
        }
        if remote {
            queryItems.append(URLQueryItem(name: "remote", value: "true"))
        }
        if onlyMedia {
            queryItems.append(URLQueryItem(name: "only_media", value: "true"))
        }
        if let maxId = maxId {
            queryItems.append(URLQueryItem(name: "max_id", value: maxId))
        }
        if let sinceId = sinceId {
            queryItems.append(URLQueryItem(name: "since_id", value: sinceId))
        }
        if let minId = minId {
            queryItems.append(URLQueryItem(name: "min_id", value: minId))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(min(limit, 40))))
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        if let accessToken = authService.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
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
        
        return try decoder.decode([Status].self, from: data)
    }
} 