//
//  MastodonMediaStatus.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import Foundation

struct MastodonMediaStatus: Sendable, Identifiable, Hashable {
    var id: String {
        attachment.id
    }

    let status: MastodonStatus
    let attachment: MastodonMediaAttachment

    init(status: MastodonStatus, attachment: MastodonMediaAttachment) {
        self.status = status
        self.attachment = attachment
    }
}
