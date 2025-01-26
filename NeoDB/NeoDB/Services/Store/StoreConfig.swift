//
//  StoreConfig.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation

enum StoreConfig {
    static let subscriptionIds = [
        "com.neodb.app.subscription.monthly",  // 月度订阅
        "com.neodb.app.subscription.yearly"    // 年度订阅
    ]
    
    static let termsURL = URL(string: "https://neodb.social/terms")!
    static let privacyURL = URL(string: "https://neodb.social/privacy")!
    
    // 订阅组 ID，需要在 App Store Connect 中配置
    static let subscriptionGroupID = "group.com.neodb.app.subscription"
}

// 订阅产品配置
extension StoreConfig {
    enum SubscriptionTier: String {
        case monthly = "com.neodb.app.subscription.monthly"
        case yearly = "com.neodb.app.subscription.yearly"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .monthly: return String(localized: "subscription_monthly_name", table: "Store")
            case .yearly: return String(localized: "subscription_yearly_name", table: "Store")
            }
        }
        
        var description: String {
            switch self {
            case .monthly: return String(localized: "subscription_monthly_description", table: "Store")
            case .yearly: return String(localized: "subscription_yearly_description", table: "Store")
            }
        }
    }
} 