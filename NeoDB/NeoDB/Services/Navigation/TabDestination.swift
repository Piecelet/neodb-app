//
//  AppTabView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/9/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI
import Defaults

enum TabDestination: String, CaseIterable, Codable {
    case timelines
    case discover
    case library
    case profile
}

extension TabDestination {
    enum Configurable: String, CaseIterable, Codable, Defaults.Serializable {
        case timelines
        case discover
        
        var tabDestination: TabDestination {
            switch self {
            case .timelines: return .timelines
            case .discover: return .discover
            }
        }
    }
}
