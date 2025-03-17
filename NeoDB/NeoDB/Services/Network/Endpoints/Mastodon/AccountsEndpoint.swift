//
//  AccountsEndpoint.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum AccountsEndpoint {
    case accounts(id: String)
    case lookup(name: String)
    case favourites(sinceId: String?)
    case bookmarks(sinceId: String?)
    case followedTags
    case featuredTags(id: String)
    case verifyCredentials
    case updateCredentialsMedia
    case updateCredentials(json: MastodonAccountUpdateCredentialsData)
    case statuses(
        id: String,
        sinceId: String?,
        tag: String?,
        onlyMedia: Bool,
        excludeReplies: Bool = true,
        excludeReblogs: Bool = false,
        pinned: Bool? = nil)
    case relationships(ids: [String])
    case follow(id: String, notify: Bool = false, reblogs: Bool = false)
    case unfollow(id: String)
    case familiarFollowers(withAccount: String)
    case suggestions
    case followers(id: String, maxId: String?)
    case following(id: String, maxId: String?)
    case lists(id: String)
    case preferences
    case block(id: String)
    case unblock(id: String)
    case mute(id: String, json: MastodonAccountMuteData)
    case unmute(id: String)
    case relationshipNote(id: String, json: MastodonAccountRelationshipNoteData)
    case blockList
    case muteList
}

extension AccountsEndpoint: NetworkEndpoint {
    var type: EndpointType {
        return .apiV1
    }

    var method: HTTPMethod {
        switch self {
        case .accounts:
            return .get
        case .lookup:
            return .get
        case .favourites:
            return .get
        case .bookmarks:
            return .get
        case .followedTags:
            return .get
        case .featuredTags:
            return .get
        case .verifyCredentials:
            return .get
        case .updateCredentials, .updateCredentialsMedia:
            return .patch
        case .statuses:
            return .get
        case .relationships:
            return .get
        case .follow:
            return .post
        case .unfollow:
            return .post
        case .familiarFollowers:
            return .get
        case .suggestions:
            return .get
        case .followers:
            return .get
        case .following:
            return .get
        case .lists:
            return .get
        case .preferences:
            return .get
        case .block:
            return .post
        case .unblock:
            return .post
        case .mute:
            return .post
        case .unmute:
            return .post
        case .relationshipNote:
            return .post
        case .blockList:
            return .get
        case .muteList:
            return .get
        }
    }

    var path: String {
        switch self {
        case .accounts(let id):
            return "/accounts/\(id)"
        case .lookup:
            return "/accounts/lookup"
        case .favourites:
            return "/favourites"
        case .bookmarks:
            return "/bookmarks"
        case .followedTags:
            return "/followed_tags"
        case .featuredTags(let id):
            return "/accounts/\(id)/featured_tags"
        case .verifyCredentials:
            return "/accounts/verify_credentials"
        case .updateCredentials, .updateCredentialsMedia:
            return "/accounts/update_credentials"
        case .statuses(let id, _, _, _, _, _, _):
            return "/accounts/\(id)/statuses"
        case .relationships:
            return "/accounts/relationships"
        case .follow(let id, _, _):
            return "/accounts/\(id)/follow"
        case .unfollow(let id):
            return "/accounts/\(id)/unfollow"
        case .familiarFollowers:
            return "/accounts/familiar_followers"
        case .suggestions:
            return "/suggestions"
        case .following(let id, _):
            return "/accounts/\(id)/following"
        case .followers(let id, _):
            return "/accounts/\(id)/followers"
        case .lists(let id):
            return "/accounts/\(id)/lists"
        case .preferences:
            return "/preferences"
        case let .block(id):
            return "/accounts/\(id)/block"
        case let .unblock(id):
            return "/accounts/\(id)/unblock"
        case let .mute(id, _):
            return "/accounts/\(id)/mute"
        case let .unmute(id):
            return "/accounts/\(id)/unmute"
        case let .relationshipNote(id, _):
            return "/accounts/\(id)/note"
        case .blockList:
            return "/blocks"
        case .muteList:
            return "/mutes"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .lookup(name):
            return [
                .init(name: "acct", value: name)
            ]
        case let .statuses(
            _, sinceId, tag, onlyMedia, excludeReplies, excludeReblogs, pinned):
            var params: [URLQueryItem] = []
            if let tag {
                params.append(.init(name: "tagged", value: tag))
            }
            if let sinceId {
                params.append(.init(name: "max_id", value: sinceId))
            }

            params.append(
                .init(name: "only_media", value: onlyMedia ? "true" : "false"))
            params.append(
                .init(
                    name: "exclude_replies",
                    value: excludeReplies ? "true" : "false"))
            params.append(
                .init(
                    name: "exclude_reblogs",
                    value: excludeReblogs ? "true" : "false"))

            if let pinned {
                params.append(
                    .init(name: "pinned", value: pinned ? "true" : "false"))
            }
            return params
        case let .relationships(ids):
            return ids.map {
                URLQueryItem(name: "id[]", value: $0)
            }
        case let .follow(_, notify, reblogs):
            return [
                .init(name: "notify", value: notify ? "true" : "false"),
                .init(name: "reblogs", value: reblogs ? "true" : "false"),
            ]
        case let .familiarFollowers(withAccount):
            return [.init(name: "id[]", value: withAccount)]
        case let .followers(_, maxId):
            return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
        case let .following(_, maxId):
            return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
        case let .favourites(sinceId):
            guard let sinceId else { return nil }
            return [.init(name: "max_id", value: sinceId)]
        case let .bookmarks(sinceId):
            guard let sinceId else { return nil }
            return [.init(name: "max_id", value: sinceId)]
        default:
            return nil
        }
    }

    var bodyJson: Encodable? {
        switch self {
        case let .mute(_, json):
            json
        case let .relationshipNote(_, json):
            json
        case let .updateCredentials(json):
            json
        default:
            nil
        }
    }
}

struct MastodonAccountMuteData: Encodable, Sendable {
    let duration: Int

    init(duration: Int) {
        self.duration = duration
    }
}

struct MastodonAccountRelationshipNoteData: Encodable, Sendable {
    let comment: String

    init(note comment: String) {
        self.comment = comment
    }
}

struct MastodonAccountUpdateCredentialsData: Encodable, Sendable {
    struct SourceData: Encodable, Sendable {
        let privacy: MastodonVisibility
        let sensitive: Bool

        init(privacy: MastodonVisibility, sensitive: Bool) {
            self.privacy = privacy
            self.sensitive = sensitive
        }
    }

    struct FieldData: Encodable, Sendable {
        let name: String
        let value: String

        init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }

    let displayName: String
    let note: String
    let source: SourceData
    let bot: Bool
    let locked: Bool
    let discoverable: Bool
    let fieldsAttributes: [String: FieldData]

    init(
        displayName: String,
        note: String,
        source: MastodonAccountUpdateCredentialsData.SourceData,
        bot: Bool,
        locked: Bool,
        discoverable: Bool,
        fieldsAttributes: [FieldData]
    ) {
        self.displayName = displayName
        self.note = note
        self.source = source
        self.bot = bot
        self.locked = locked
        self.discoverable = discoverable

        var fieldAttributes: [String: FieldData] = [:]
        for (index, field) in fieldsAttributes.enumerated() {
            fieldAttributes[String(index)] = field
        }
        self.fieldsAttributes = fieldAttributes
    }
}
