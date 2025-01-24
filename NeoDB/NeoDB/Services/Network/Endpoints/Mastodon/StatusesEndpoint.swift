//
//  StatusesEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum StatusesEndpoints {
    case postStatus(json: StatusData)
    case editStatus(id: String, json: StatusData)
    case status(id: String)
    case context(id: String)
    case favorite(id: String)
    case unfavorite(id: String)
    case reblog(id: String)
    case unreblog(id: String)
    case rebloggedBy(id: String, maxId: String?)
    case favoritedBy(id: String, maxId: String?)
    case pin(id: String)
    case unpin(id: String)
    case bookmark(id: String)
    case unbookmark(id: String)
    case history(id: String)
    case translate(id: String, lang: String?)
    case report(accountId: String, statusId: String, comment: String)
}

extension StatusesEndpoints: NetworkEndpoint {
    var path: String {
        switch self {
        case .postStatus:
            "/v1/statuses"
        case let .status(id):
            "/v1/statuses/\(id)"
        case let .editStatus(id, _):
            "/v1/statuses/\(id)"
        case let .context(id):
            "/v1/statuses/\(id)/context"
        case let .favorite(id):
            "/v1/statuses/\(id)/favourite"
        case let .unfavorite(id):
            "/v1/statuses/\(id)/unfavourite"
        case let .reblog(id):
            "/v1/statuses/\(id)/reblog"
        case let .unreblog(id):
            "/v1/statuses/\(id)/unreblog"
        case let .rebloggedBy(id, _):
            "/v1/statuses/\(id)/reblogged_by"
        case let .favoritedBy(id, _):
            "/v1/statuses/\(id)/favourited_by"
        case let .pin(id):
            "/v1/statuses/\(id)/pin"
        case let .unpin(id):
            "/v1/statuses/\(id)/unpin"
        case let .bookmark(id):
            "/v1/statuses/\(id)/bookmark"
        case let .unbookmark(id):
            "/v1/statuses/\(id)/unbookmark"
        case let .history(id):
            "/v1/statuses/\(id)/history"
        case let .translate(id, _):
            "/v1/statuses/\(id)/translate"
        case .report:
            "/v1/reports"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .postStatus:
            return .post
        case .favorite:
            return .post
        case .unfavorite:
            return .post
        case .reblog:
            return .post
        case .unreblog:
            return .post
        case .bookmark:
            return .post
        case .unbookmark:
            return .post
        case .pin:
            return .post
        case .unpin:
            return .post
        case .translate:
            return .post
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .rebloggedBy(_, maxId):
            return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
        case let .favoritedBy(_, maxId):
            return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
        case let .translate(_, lang):
            if let lang {
                return [.init(name: "lang", value: lang)]
            }
            return nil
        case let .report(accountId, statusId, comment):
            return [
                .init(name: "account_id", value: accountId),
                .init(name: "status_ids[]", value: statusId),
                .init(name: "comment", value: comment),
            ]
        default:
            return nil
        }
    }

    var bodyJson: Encodable? {
        switch self {
        case let .postStatus(json):
            return json
        case let .editStatus(_, json):
            return json
        default:
            return nil
        }
    }
}

struct StatusData: Encodable, Sendable {
    let status: String
    let visibility: MastodonVisibility
    let inReplyToId: String?
    let spoilerText: String?
    let mediaIds: [String]?
    let poll: PollData?
    let language: String?
    let mediaAttributes: [MediaAttribute]?

    struct PollData: Encodable, Sendable {
        let options: [String]
        let multiple: Bool
        let expires_in: Int

        init(options: [String], multiple: Bool, expires_in: Int) {
            self.options = options
            self.multiple = multiple
            self.expires_in = expires_in
        }
    }

    struct MediaAttribute: Encodable, Sendable {
        let id: String
        let description: String?
        let thumbnail: String?
        let focus: String?

        init(
            id: String, description: String?, thumbnail: String?, focus: String?
        ) {
            self.id = id
            self.description = description
            self.thumbnail = thumbnail
            self.focus = focus
        }
    }

    init(
        status: String,
        visibility: MastodonVisibility,
        inReplyToId: String? = nil,
        spoilerText: String? = nil,
        mediaIds: [String]? = nil,
        poll: PollData? = nil,
        language: String? = nil,
        mediaAttributes: [MediaAttribute]? = nil
    ) {
        self.status = status
        self.visibility = visibility
        self.inReplyToId = inReplyToId
        self.spoilerText = spoilerText
        self.mediaIds = mediaIds
        self.poll = poll
        self.language = language
        self.mediaAttributes = mediaAttributes
    }
}
