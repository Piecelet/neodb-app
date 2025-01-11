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
            return "/book/\(uuid)"
        case .fetchMovie(let uuid):
            return "/movie/\(uuid)"
        case .fetchTVShow(let uuid):
            return "/tv/\(uuid)"
        case .fetchTVSeason(let uuid):
            return "/tv/season/\(uuid)"
        case .fetchTVEpisode(let uuid):
            return "/tv/episode/\(uuid)"
        case .fetchPodcast(let uuid):
            return "/podcast/\(uuid)"
        case .fetchAlbum(let uuid):
            return "/album/\(uuid)"
        case .fetchGame(let uuid):
            return "/game/\(uuid)"
        case .fetchPerformance(let uuid):
            return "/performance/\(uuid)"
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