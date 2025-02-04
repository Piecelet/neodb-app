//
//  AppInfo.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation

struct AppInfo {
    enum bundle {
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        static let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
    }
}
