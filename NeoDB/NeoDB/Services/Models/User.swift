import Foundation

struct User: Codable {
    let url: String
    let externalAcct: String?
    let displayName: String
    let avatar: String
    let username: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case externalAcct = "external_acct"
        case displayName = "display_name"
        case avatar
        case username
    }
} 