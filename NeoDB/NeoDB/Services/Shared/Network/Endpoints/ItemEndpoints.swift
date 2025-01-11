import Foundation

enum ItemEndpoints {
    case fetchBook(uuid: String)
    case fetchMovie(uuid: String)
    case fetchTVShow(uuid: String)
    case fetchTVSeason(uuid: String)
    case fetchTVEpisode(uuid: String)
    case fetchPodcast(uuid: String)
    case fetchAlbum(uuid: String)
    case fetchGame(uuid: String)
    case fetchPerformance(uuid: String)
}

extension ItemEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .fetchBook(let uuid):
            return "/api/book/\(uuid)"
        case .fetchMovie(let uuid):
            return "/api/movie/\(uuid)"
        case .fetchTVShow(let uuid):
            return "/api/tv/\(uuid)"
        case .fetchTVSeason(let uuid):
            return "/api/tv/season/\(uuid)"
        case .fetchTVEpisode(let uuid):
            return "/api/tv/episode/\(uuid)"
        case .fetchPodcast(let uuid):
            return "/api/podcast/\(uuid)"
        case .fetchAlbum(let uuid):
            return "/api/album/\(uuid)"
        case .fetchGame(let uuid):
            return "/api/game/\(uuid)"
        case .fetchPerformance(let uuid):
            return "/api/performance/\(uuid)"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        return nil
    }
} 