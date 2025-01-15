////
////  ItemDetailService.swift
////  NeoDB
////
////  Created by citron(https://github.com/lcandy2) on 1/7/25.
////
//
//import Foundation
//import OSLog
//import Cache
//
//@MainActor
//class ItemDetailService {
//    private let authService: AuthService
//    private let router: Router
//    private let logger = Logger.networkItem
//    
//    // Add separate caches for each type
//    private let bookStorage: Storage<String, EditionSchema>
//    private let movieStorage: Storage<String, MovieSchema>
//    private let tvShowStorage: Storage<String, TVShowSchema>
//    private let tvSeasonStorage: Storage<String, TVSeasonSchema>
//    private let tvEpisodeStorage: Storage<String, TVEpisodeSchema>
//    private let albumStorage: Storage<String, AlbumSchema>
//    private let gameStorage: Storage<String, GameSchema>
//    private let podcastStorage: Storage<String, PodcastSchema>
//    private let performanceStorage: Storage<String, PerformanceSchema>
//    
//    init(authService: AuthService, router: Router) {
//        self.authService = authService
//        self.router = router
//        
//        // Initialize cache storage
//        let fileManager = FileManager.default
//        let diskConfig = DiskConfig(
//            name: "ItemDetail",
//            expiry: .date(Date().addingTimeInterval(24 * 60 * 60)), // 24 hours
//            maxSize: 50 * 1024 * 1024 // 50 MB
//        )
//        
//        let memoryConfig = MemoryConfig(
//            expiry: .date(Date().addingTimeInterval(30 * 60)), // 30 minutes
//            countLimit: 50,
//            totalCostLimit: 10 * 1024 * 1024 // 10 MB
//        )
//        
//        do {
//            bookStorage = try Storage(
//                diskConfig: diskConfig,
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: EditionSchema.self)
//            )
//            movieStorage = try Storage(
//                diskConfig: DiskConfig(name: "MovieDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: MovieSchema.self)
//            )
//            tvShowStorage = try Storage(
//                diskConfig: DiskConfig(name: "TVShowDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: TVShowSchema.self)
//            )
//            tvSeasonStorage = try Storage(
//                diskConfig: DiskConfig(name: "TVSeasonDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: TVSeasonSchema.self)
//            )
//            tvEpisodeStorage = try Storage(
//                diskConfig: DiskConfig(name: "TVEpisodeDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: TVEpisodeSchema.self)
//            )
//            albumStorage = try Storage(
//                diskConfig: DiskConfig(name: "AlbumDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: AlbumSchema.self)
//            )
//            gameStorage = try Storage(
//                diskConfig: DiskConfig(name: "GameDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: GameSchema.self)
//            )
//            podcastStorage = try Storage(
//                diskConfig: DiskConfig(name: "PodcastDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: PodcastSchema.self)
//            )
//            performanceStorage = try Storage(
//                diskConfig: DiskConfig(name: "PerformanceDetail", expiry: diskConfig.expiry, maxSize: diskConfig.maxSize),
//                memoryConfig: memoryConfig,
//                fileManager: fileManager,
//                transformer: TransformerFactory.forCodable(ofType: PerformanceSchema.self)
//            )
//        } catch {
//            logger.error("Failed to initialize cache storage: \(error)")
//            fatalError("Cache initialization failed")
//        }
//    }
//    
//    private func fetchItem<T: Codable>(endpoint: String) async throws -> T {
//        guard let accessToken = authService.accessToken else {
//            throw AuthError.unauthorized
//        }
//        
//        let baseURL = "https://\(authService.currentInstance)"
//        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
//            logger.error("Invalid URL: \(baseURL)\(endpoint)")
//            throw AuthError.invalidURL
//        }
//        
//        var request = URLRequest(url: url)
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        
//        logger.debug("Fetching item from: \(endpoint)")
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        guard let httpResponse = response as? HTTPURLResponse else {
//            logger.error("Invalid response type")
//            throw AuthError.invalidResponse
//        }
//        
//        guard httpResponse.statusCode == 200 else {
//            if httpResponse.statusCode == 401 {
//                logger.error("Unauthorized request")
//                throw AuthError.unauthorized
//            }
//            if httpResponse.statusCode == 302,
//               let redirectResponse = try? JSONDecoder().decode(RedirectedResult.self, from: data) {
//                logger.notice("Redirected to: \(redirectResponse.url)")
//                // Handle redirection by recursively calling with new URL
//                let newEndpoint = redirectResponse.url.replacingOccurrences(of: baseURL, with: "")
//                return try await fetchItem(endpoint: newEndpoint)
//            }
//            logger.error("HTTP error: \(httpResponse.statusCode)")
//            throw AuthError.invalidResponse
//        }
//        
//        do {
//            let decoder = JSONDecoder()
//            decoder.keyDecodingStrategy = .convertFromSnakeCase
//            return try decoder.decode(T.self, from: data)
//        } catch {
//            logger.error("Decoding error: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    func fetchBook(uuid: String) async throws -> EditionSchema {
//        return try await fetchItem(endpoint: "/api/book/\(uuid)")
//    }
//    
//    func fetchMovie(uuid: String) async throws -> MovieSchema {
//        return try await fetchItem(endpoint: "/api/movie/\(uuid)")
//    }
//    
//    func fetchTVShow(uuid: String) async throws -> TVShowSchema {
//        return try await fetchItem(endpoint: "/api/tv/\(uuid)")
//    }
//    
//    func fetchTVSeason(uuid: String) async throws -> TVSeasonSchema {
//        return try await fetchItem(endpoint: "/api/tv/season/\(uuid)")
//    }
//    
//    func fetchTVEpisode(uuid: String) async throws -> TVEpisodeSchema {
//        return try await fetchItem(endpoint: "/api/tv/episode/\(uuid)")
//    }
//    
//    func fetchPodcast(uuid: String) async throws -> PodcastSchema {
//        return try await fetchItem(endpoint: "/api/podcast/\(uuid)")
//    }
//    
//    func fetchAlbum(uuid: String) async throws -> AlbumSchema {
//        return try await fetchItem(endpoint: "/api/album/\(uuid)")
//    }
//    
//    func fetchGame(uuid: String) async throws -> GameSchema {
//        return try await fetchItem(endpoint: "/api/game/\(uuid)")
//    }
//    
//    func fetchPerformance(uuid: String) async throws -> PerformanceSchema {
//        return try await fetchItem(endpoint: "/api/performance/\(uuid)")
//    }
//    
//    func fetchPerformanceProduction(uuid: String) async throws -> PerformanceProductionSchema {
//        return try await fetchItem(endpoint: "/api/performance/production/\(uuid)")
//    }
//    
//    func fetchItemDetail(id: String, category: ItemCategory) async throws -> any ItemDetailProtocol {
//        // Try cache first
//        if let cachedItem = try? getCachedItem(id: id, category: category) {
//            // Return cached data and refresh in background
//            Task {
//                await refreshItemInBackground(id: id, category: category)
//            }
//            return cachedItem
//        }
//        
//        // If no cache, fetch from network once
//        let item = try await fetchItemFromNetwork(id: id, category: category)
//        try? cacheItem(item, id: id, category: category)
//        return item
//    }
//    
//    private func getCachedItem(id: String, category: ItemCategory) throws -> (any ItemDetailProtocol)? {
//        switch category {
//        case .book:
//            return try bookStorage.object(forKey: id)
//        case .movie:
//            return try movieStorage.object(forKey: id)
//        case .tv:
//            return try tvShowStorage.object(forKey: id)
//        case .tvSeason:
//            return try tvSeasonStorage.object(forKey: id)
//        case .tvEpisode:
//            return try tvEpisodeStorage.object(forKey: id)
//        case .music:
//            return try albumStorage.object(forKey: id)
//        case .game:
//            return try gameStorage.object(forKey: id)
//        case .podcast:
//            return try podcastStorage.object(forKey: id)
//        case .performance:
//            return try performanceStorage.object(forKey: id)
//        default:
//            return nil
//        }
//    }
//    
//    private func cacheItem(_ item: any ItemDetailProtocol, id: String, category: ItemCategory) throws {
//        switch category {
//        case .book:
//            if let book = item as? EditionSchema {
//                try bookStorage.setObject(book, forKey: id)
//            }
//        case .movie:
//            if let movie = item as? MovieSchema {
//                try movieStorage.setObject(movie, forKey: id)
//            }
//        case .tv:
//            if let show = item as? TVShowSchema {
//                try tvShowStorage.setObject(show, forKey: id)
//            }
//        case .tvSeason:
//            if let season = item as? TVSeasonSchema {
//                try tvSeasonStorage.setObject(season, forKey: id)
//            }
//        case .tvEpisode:
//            if let episode = item as? TVEpisodeSchema {
//                try tvEpisodeStorage.setObject(episode, forKey: id)
//            }
//        case .music:
//            if let album = item as? AlbumSchema {
//                try albumStorage.setObject(album, forKey: id)
//            }
//        case .game:
//            if let game = item as? GameSchema {
//                try gameStorage.setObject(game, forKey: id)
//            }
//        case .podcast:
//            if let podcast = item as? PodcastSchema {
//                try podcastStorage.setObject(podcast, forKey: id)
//            }
//        case .performance:
//            if let performance = item as? PerformanceSchema {
//                try performanceStorage.setObject(performance, forKey: id)
//            }
//        default:
//            break
//        }
//    }
//    
//    private func fetchItemFromNetwork(id: String, category: ItemCategory) async throws -> any ItemDetailProtocol {
//        switch category {
//        case .book:
//            return try await fetchBook(uuid: id)
//        case .movie:
//            return try await fetchMovie(uuid: id)
//        case .tv:
//            return try await fetchTVShow(uuid: id)
//        case .tvSeason:
//            return try await fetchTVSeason(uuid: id)
//        case .tvEpisode:
//            return try await fetchTVEpisode(uuid: id)
//        case .music:
//            return try await fetchAlbum(uuid: id)
//        case .game:
//            return try await fetchGame(uuid: id)
//        case .podcast:
//            return try await fetchPodcast(uuid: id)
//        case .performance:
//            return try await fetchPerformance(uuid: id)
//        default:
//            logger.error("Unsupported category: \(category.rawValue)")
//            throw ItemDetailError.unsupportedCategory
//        }
//    }
//    
//    // Add method to clear all caches
//    func clearCache() {
//        try? bookStorage.removeAll()
//        try? movieStorage.removeAll()
//        try? tvShowStorage.removeAll()
//        try? tvSeasonStorage.removeAll()
//        try? tvEpisodeStorage.removeAll()
//        try? albumStorage.removeAll()
//        try? gameStorage.removeAll()
//        try? podcastStorage.removeAll()
//        try? performanceStorage.removeAll()
//        logger.debug("All caches cleared")
//    }
//    
//    // Add method to remove expired items from all caches
//    func removeExpiredItems() {
//        try? bookStorage.removeExpiredObjects()
//        try? movieStorage.removeExpiredObjects()
//        try? tvShowStorage.removeExpiredObjects()
//        try? tvSeasonStorage.removeExpiredObjects()
//        try? tvEpisodeStorage.removeExpiredObjects()
//        try? albumStorage.removeExpiredObjects()
//        try? gameStorage.removeExpiredObjects()
//        try? podcastStorage.removeExpiredObjects()
//        try? performanceStorage.removeExpiredObjects()
//        logger.debug("Removed expired items from all caches")
//    }
//    
//    // Add a new method for background refresh
//    func refreshItemInBackground(id: String, category: ItemCategory) async {
//        do {
//            logger.debug("Background refresh for item: \(id)")
//            let item = try await fetchItemFromNetwork(id: id, category: category)
//            try? cacheItem(item, id: id, category: category)
//            logger.debug("Background refresh completed for item: \(id)")
//        } catch {
//            logger.error("Background refresh failed for item: \(id): \(error.localizedDescription)")
//        }
//    }
//}
//
//enum ItemDetailError: Error {
//    case unsupportedCategory
//}
//
//protocol ItemDetailProtocol: Codable {
//    var id: String { get }
//    var type: String { get }
//    var uuid: String { get }
//    var url: String { get }
//    var apiUrl: String { get }
//    var category: ItemCategory { get }
//    var parentUuid: String? { get }
//    var displayTitle: String { get }
//    var externalResources: [ExternalResourceSchema]? { get }
//    var title: String { get }
//    var description: String { get }
//    var localizedTitle: [LocalizedTitleSchema] { get }
//    var localizedDescription: [LocalizedTitleSchema] { get }
//    var coverImageUrl: String? { get }
//    var rating: Double? { get }
//    var ratingCount: Int? { get }
//}
//
//extension EditionSchema: ItemDetailProtocol {}
//extension MovieSchema: ItemDetailProtocol {}
//extension TVShowSchema: ItemDetailProtocol {}
//extension TVSeasonSchema: ItemDetailProtocol {}
//extension TVEpisodeSchema: ItemDetailProtocol {}
//extension AlbumSchema: ItemDetailProtocol {}
//extension PodcastSchema: ItemDetailProtocol {}
//extension GameSchema: ItemDetailProtocol {}
//extension PerformanceSchema: ItemDetailProtocol {}
//extension PerformanceProductionSchema: ItemDetailProtocol {}
