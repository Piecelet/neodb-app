import Foundation

enum TimelineEndpoint {
    case pub(sinceId: String?, maxId: String?, minId: String?, local: Bool)
    case home(sinceId: String?, maxId: String?, minId: String?)
}

extension TimelineEndpoint: NetworkEndpoint {
    var path: String {
        switch self {
        case .pub:
            return "/timelines/public"
        case .home:
            return "/timelines/home"
        }
    }
    var queryItems: [URLQueryItem]? {
        switch self {
        case .pub(let sinceId, let maxId, let minId, let local):
            var params =
                makePaginationParam(
                    sinceId: sinceId, maxId: maxId, mindId: minId) ?? []
            params.append(.init(name: "local", value: local ? "true" : "false"))
            return params
        case .home(let sinceId, let maxId, let mindId):
            return makePaginationParam(
                sinceId: sinceId, maxId: maxId, mindId: mindId)
        }
    }
}
