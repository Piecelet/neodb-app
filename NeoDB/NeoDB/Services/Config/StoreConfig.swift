//
//  StoreConfig.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation
import SwiftUI

enum StoreConfig {
    enum URLs {
        static let privacyPolicy = URL(string: "https://piecelet.app/privacy")!
        static let termsOfService = URL(string: "https://piecelet.app/terms")!
    }
    
    enum RevenueCat {
        static let apiKey = "appl_piTjpqjRBRGEtJCEVXwILxxKmvY"
        static let proxyURL = URL(string: "https://rc.piecelet.app")!
        enum plus {
            static let entitlementName = "plus"
            static let offeringIdentifier = "plu"
        }

    }
    
    struct Feature: Identifiable {
        let id = UUID()
        let icon: Symbol
        let title: String
        let description: String
        let isComingSoon: Bool
        let isFree: Bool
        let color: Color
        
        init(
            icon: Symbol,
            title: String,
            description: String,
            isComingSoon: Bool = false,
            isFree: Bool = false,
            color: Color = .accentColor
        ) {
            self.icon = icon
            self.title = title
            self.description = description
            self.isComingSoon = isComingSoon
            self.isFree = isFree
            self.color = color
        }
    }
    
    static let features: [Feature] = [
        Feature(
            icon: .sfSymbol(.sparkles),
            title: String(localized: "store_feature_smooth_title", table: "Settings"),
            description: String(localized: "store_feature_smooth_description", table: "Settings"),
            isFree: true,
            color: .pink
        ),
        Feature(
            icon: .sfSymbol(.infinity),
            title: String(localized: "store_feature_unlimited_title", table: "Settings"),
            description: String(localized: "store_feature_unlimited_description", table: "Settings"),
            isFree: true,
            color: .mint
        ),
        Feature(
            icon: .sfSymbol(.magnifyingglassCircle),
            title: String(localized: "store_feature_discovery_title", table: "Settings"),
            description: String(localized: "store_feature_discovery_description", table: "Settings"),
            isFree: true,
            color: .cyan
        ),
        Feature(
            icon: .sfSymbol(.personCropCircle),
            title: String(localized: "store_feature_accounts_title", table: "Settings"),
            description: String(localized: "store_feature_accounts_description", table: "Settings"),
            color: .blue
        ),
        Feature(
            icon: .sfSymbol(.heart),
            title: String(localized: "store_feature_support_dev_title", table: "Settings"),
            description: String(localized: "store_feature_support_dev_description", table: "Settings"),
            color: .red
        ),
        Feature(
            icon: .sfSymbol(.handRaised),
            title: String(localized: "store_feature_support_community_title", table: "Settings"),
            description: String(localized: "store_feature_support_community_description", table: "Settings"),
            color: .teal
        ),
        Feature(
            icon: .sfSymbol(.arrowTriangle2Circlepath),
            title: String(localized: "store_feature_sync_title", table: "Settings"),
            description: String(localized: "store_feature_sync_description", table: "Settings"),
            isComingSoon: true,
            color: .purple
        ),
        Feature(
            icon: .sfSymbol(.magnifyingglass),
            title: String(localized: "store_feature_search_title", table: "Settings"),
            description: String(localized: "store_feature_search_description", table: "Settings"),
            isComingSoon: true,
            color: .orange
        ),
        Feature(
            icon: .sfSymbol(.arrowLeftArrowRight),
            title: String(localized: "store_feature_actions_title", table: "Settings"),
            description: String(localized: "store_feature_actions_description", table: "Settings"),
            isComingSoon: true,
            color: .green
        ),
        Feature(
            icon: .sfSymbol(.bell),
            title: String(localized: "store_feature_updates_title", table: "Settings"),
            description: String(localized: "store_feature_updates_description", table: "Settings"),
            isComingSoon: true,
            color: .red
        ),
        Feature(
            icon: .sfSymbol(.checklist),
            title: String(localized: "store_feature_batch_title", table: "Settings"),
            description: String(localized: "store_feature_batch_description", table: "Settings"),
            isComingSoon: true,
            color: .indigo
        )
    ]
}
