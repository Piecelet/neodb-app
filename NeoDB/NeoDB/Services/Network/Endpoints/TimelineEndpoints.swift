import Foundation

enum TimelineEndpoints {
    case fetchTimeline(page: Int)
    case fetchLocalTimeline(page: Int)
}

extension TimelineEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .fetchTimeline:
            return "/timeline"
        case .fetchLocalTimeline:
            return "/timeline/local"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .fetchTimeline(let page), .fetchLocalTimeline(let page):
            return [URLQueryItem(name: "page", value: String(page))]
        }
    }
    
    var body: Data? {
        return nil
    }
} 