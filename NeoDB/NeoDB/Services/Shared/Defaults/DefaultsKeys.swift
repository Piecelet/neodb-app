//
//  DefaultsKeys.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/10/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Defaults

// MARK: - Settings

extension Defaults.Keys {
    static let defaultTab = Key<TabDestination.Configurable>("settings_defaultTab", default: .home)
}
