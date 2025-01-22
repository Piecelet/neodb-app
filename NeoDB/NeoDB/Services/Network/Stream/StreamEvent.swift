//
//  StreamEvent.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import Foundation

struct RawStreamEvent: Decodable {
    let event: String
    let stream: [String]
    let payload: String
}

struct StreamMessage: Encodable {
    let type: String
    let stream: String
}

protocol StreamEvent: Identifiable {
    var date: Date { get }
    var id: String { get }
}

struct StreamEventUpdate: StreamEvent {
    let date = Date()
    var id: String { status.id }
    let status: MastodonStatus
}

struct StreamEventStatusUpdate: StreamEvent {
    let date = Date()
    var id: String { status.id }
    let status: MastodonStatus
}

struct StreamEventDelete: StreamEvent {
    let date = Date()
    var id: String { status + date.description }
    let status: String
} 