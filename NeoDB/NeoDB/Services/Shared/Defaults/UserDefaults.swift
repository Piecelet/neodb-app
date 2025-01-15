//
//  UserDefaults.swift
//  NeoDB
//
//  Created by citron on 1/12/25.
//

import Foundation

extension UserDefaults {
    enum Keys {
        // Account related
        static let currentInstance = "current_instance"
        static let accessToken = "access_token"
        static let username = "username"
        
        // App settings (預留未來可能會用到的)
        static let appTheme = "app_theme"
        static let cacheExpiry = "cache_expiry"
        
        // 預設值
        static let defaultInstance = "neodb.social"
    }
    
    // Convenience accessors
    var currentInstance: String {
        get { string(forKey: Keys.currentInstance) ?? Keys.defaultInstance }
        set { set(newValue, forKey: Keys.currentInstance) }
    }
    
    var accessToken: String? {
        get { string(forKey: Keys.accessToken) }
        set { set(newValue, forKey: Keys.accessToken) }
    }
}
