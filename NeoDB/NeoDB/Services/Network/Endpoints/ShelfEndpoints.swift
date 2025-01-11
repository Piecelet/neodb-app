import Foundation

enum ShelfEndpoints {
    case fetchShelves
    case addToShelf(itemId: String, shelfId: String)
    case removeFromShelf(itemId: String, shelfId: String)
}

extension ShelfEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .fetchShelves:
            return "/shelves"
        case .addToShelf(_, let shelfId):
            return "/shelf/\(shelfId)/add"
        case .removeFromShelf(_, let shelfId):
            return "/shelf/\(shelfId)/remove"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .fetchShelves:
            return .get
        case .addToShelf:
            return .post
        case .removeFromShelf:
            return .delete
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .addToShelf(let itemId, _), .removeFromShelf(let itemId, _):
            return [URLQueryItem(name: "item_id", value: itemId)]
        default:
            return nil
        }
    }
    
    var body: Data? {
        return nil
    }
} 