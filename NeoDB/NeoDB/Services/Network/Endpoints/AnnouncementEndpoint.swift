//
//  AnnouncementEndpoint.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

enum AnnouncementEndpoint {
    case get
}

extension AnnouncementEndpoint: NetworkEndpoint {
    var type: EndpointType {
        return .apiV1
    }

    var path: String {
        return "/announcements"
    }
}
