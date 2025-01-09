import Foundation
import OSLog

@MainActor
class ItemDetailService {
    private let authService: AuthService
    private let router: Router
    private let logger = Logger(subsystem: "app.neodb", category: "ItemDetail")
    
    init(authService: AuthService, router: Router) {
        self.authService = authService
        self.router = router
    }
    
    private func fetchItem<T: Codable>(endpoint: String) async throws -> T {
        guard let accessToken = authService.accessToken else {
            throw AuthError.unauthorized
        }
        
        let baseURL = "https://\(authService.currentInstance)"
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logger.error("Invalid URL: \(baseURL)\(endpoint)")
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        logger.debug("Fetching item from: \(endpoint)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                logger.error("Unauthorized request")
                throw AuthError.unauthorized
            }
            if httpResponse.statusCode == 302,
               let redirectResponse = try? JSONDecoder().decode(RedirectedResult.self, from: data) {
                logger.notice("Redirected to: \(redirectResponse.url)")
                // Handle redirection by recursively calling with new URL
                let newEndpoint = redirectResponse.url.replacingOccurrences(of: baseURL, with: "")
                return try await fetchItem(endpoint: newEndpoint)
            }
            logger.error("HTTP error: \(httpResponse.statusCode)")
            throw AuthError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchBook(uuid: String) async throws -> EditionSchema {
        return try await fetchItem(endpoint: "/api/book/\(uuid)")
    }
    
    func fetchMovie(uuid: String) async throws -> MovieSchema {
        return try await fetchItem(endpoint: "/api/movie/\(uuid)")
    }
    
    func fetchTVShow(uuid: String) async throws -> TVShowSchema {
        return try await fetchItem(endpoint: "/api/tv/\(uuid)")
    }
    
    func fetchTVSeason(uuid: String) async throws -> TVSeasonSchema {
        return try await fetchItem(endpoint: "/api/tv/season/\(uuid)")
    }
    
    func fetchTVEpisode(uuid: String) async throws -> TVEpisodeSchema {
        return try await fetchItem(endpoint: "/api/tv/episode/\(uuid)")
    }
    
    func fetchPodcast(uuid: String) async throws -> PodcastSchema {
        return try await fetchItem(endpoint: "/api/podcast/\(uuid)")
    }
    
    func fetchAlbum(uuid: String) async throws -> AlbumSchema {
        return try await fetchItem(endpoint: "/api/album/\(uuid)")
    }
    
    func fetchGame(uuid: String) async throws -> GameSchema {
        return try await fetchItem(endpoint: "/api/game/\(uuid)")
    }
    
    func fetchPerformance(uuid: String) async throws -> PerformanceSchema {
        return try await fetchItem(endpoint: "/api/performance/\(uuid)")
    }
    
    func fetchPerformanceProduction(uuid: String) async throws -> PerformanceProductionSchema {
        return try await fetchItem(endpoint: "/api/performance/production/\(uuid)")
    }
    
    func fetchItemDetail(id: String, category: ItemCategory) async throws -> any ItemDetailProtocol {
        switch category {
        case .book:
            return try await fetchBook(uuid: id)
        case .movie:
            return try await fetchMovie(uuid: id)
        case .tv:
            return try await fetchTVShow(uuid: id)
        case .tvSeason:
            return try await fetchTVSeason(uuid: id)
        case .tvEpisode:
            return try await fetchTVEpisode(uuid: id)
        case .music:
            return try await fetchAlbum(uuid: id)
        case .game:
            return try await fetchGame(uuid: id)
        case .podcast:
            return try await fetchPodcast(uuid: id)
        case .performance:
            return try await fetchPerformance(uuid: id)
        default:
            logger.error("Unsupported category: \(category.rawValue)")
            throw ItemDetailError.unsupportedCategory
        }
    }
}

enum ItemDetailError: Error {
    case unsupportedCategory
}

protocol ItemDetailProtocol: Codable {
    var id: String { get }
    var type: String { get }
    var uuid: String { get }
    var url: String { get }
    var apiUrl: String { get }
    var category: ItemCategory { get }
    var parentUuid: String? { get }
    var displayTitle: String { get }
    var externalResources: [ExternalResourceSchema]? { get }
    var title: String { get }
    var description: String { get }
    var localizedTitle: [LocalizedTitleSchema] { get }
    var localizedDescription: [LocalizedTitleSchema] { get }
    var coverImageUrl: String? { get }
    var rating: Double? { get }
    var ratingCount: Int? { get }
}

extension EditionSchema: ItemDetailProtocol {}
extension MovieSchema: ItemDetailProtocol {}
extension TVShowSchema: ItemDetailProtocol {}
extension TVSeasonSchema: ItemDetailProtocol {}
extension TVEpisodeSchema: ItemDetailProtocol {}
extension AlbumSchema: ItemDetailProtocol {}
extension PodcastSchema: ItemDetailProtocol {}
extension GameSchema: ItemDetailProtocol {}
extension PerformanceSchema: ItemDetailProtocol {}
extension PerformanceProductionSchema: ItemDetailProtocol {} 