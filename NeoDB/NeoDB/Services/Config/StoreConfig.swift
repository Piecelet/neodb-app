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
    
    enum Features: CaseIterable {
        case smooth
        case unlimited
        case discovery
        case integration
        case customize
        case multipleAccounts
        case supportDev
        case supportCommunity
        case sync
        case search
        case updates
        case batch
        
        var feature: Feature {
            switch self {
            case .multipleAccounts:
                return Feature(
                    icon: .sfSymbol(.personCropCircle),
                    title: String(localized: "store_feature_accounts_title", defaultValue: "Multiple Accounts", table: "Settings"),
                    description: String(localized: "store_feature_accounts_description", defaultValue: "Connect and switch between multiple NeoDB accounts seamlessly.", table: "Settings"),
                    color: .blue
                )
            case .integration:
                return Feature(
                    icon: .sfSymbol(.sparkles),
                    title: String(localized: "store_feature_integration_title", defaultValue: "Integration with Apps", table: "Settings"),
                    description: String(localized: "store_feature_integration_description", defaultValue: "Integrate with apps to search or open items in only one touch.", table: "Settings"),
                    color: .green
                )
            case .customize:
                return Feature(
                    icon: .sfSymbol(.sparkles),
                    title: String(localized: "store_feature_customize_title", defaultValue: "Customize", table: "Settings"),
                    description: String(localized: "store_feature_customize_description", defaultValue: "Personalize your NeoDB experience to your liking.", table: "Settings"),
                    color: .blue
                )
            case .smooth:
                return Feature(
                    icon: .sfSymbol(.arrowLeftArrowRight),
                    title: String(localized: "store_feature_smooth_title", defaultValue: "Smooth Experience", table: "Settings"),
                    description: String(localized: "store_feature_smooth_description", defaultValue: "Enjoy a fluid and responsive experience for browsing and managing your collections.", table: "Settings"),
                    isFree: true,
                    color: .pink
                )
            case .unlimited:
                return Feature(
                    icon: .sfSymbol(.infinity),
                    title: String(localized: "store_feature_unlimited_title", defaultValue: "Unlimited Collections", table: "Settings"),
                    description: String(localized: "store_feature_unlimited_description", defaultValue: "Mark and collect unlimited books, movies, and music without restrictions.", table: "Settings"),
                    isFree: true,
                    color: .mint
                )
            case .discovery:
                return Feature(
                    icon: .sfSymbol(.magnifyingglassCircle),
                    title: String(localized: "store_feature_discovery_title", defaultValue: "Quick Discovery", table: "Settings"),
                    description: String(localized: "store_feature_discovery_description", defaultValue: "Instantly search and discover trending books, movies, and music.", table: "Settings"),
                    isFree: true,
                    color: .cyan
                )
            case .supportDev:
                return Feature(
                    icon: .sfSymbol(.heart),
                    title: String(localized: "store_feature_support_dev_title", defaultValue: "Support Future Development", table: "Settings"),
                    description: String(localized: "store_feature_support_dev_description", defaultValue: "Help a student developer continue building and improving Piecelet.", table: "Settings"),
                    color: .red
                )
            case .supportCommunity:
                return Feature(
                    icon: .sfSymbol(.handRaised),
                    title: String(localized: "store_feature_support_community_title", defaultValue: "Support NeoDB Community", table: "Settings"),
                    description: String(localized: "store_feature_support_community_description", defaultValue: "Part of the revenue will be donated to support the NeoDB open source project.", table: "Settings"),
                    color: .teal
                )
            case .sync:
                return Feature(
                    icon: .sfSymbol(.arrowTriangle2Circlepath),
                    title: String(localized: "store_feature_sync_title", defaultValue: "Cross-platform Sync", table: "Settings"),
                    description: String(localized: "store_feature_sync_description", defaultValue: "Sync your marks with Trakt, Douban, Letterboxd, Goodreads, and more.", table: "Settings"),
                    isComingSoon: true,
                    color: .purple
                )
            case .search:
                return Feature(
                    icon: .sfSymbol(.magnifyingglass),
                    title: String(localized: "store_feature_search_title", defaultValue: "Enhanced Search", table: "Settings"),
                    description: String(localized: "store_feature_search_description", defaultValue: "Access additional search sources for better results.", table: "Settings"),
                    isComingSoon: true,
                    color: .orange
                )
            case .updates:
                return Feature(
                    icon: .sfSymbol(.bell),
                    title: String(localized: "store_feature_updates_title", defaultValue: "Series Updates", table: "Settings"),
                    description: String(localized: "store_feature_updates_description", defaultValue: "Track and share your books, movies, music, and more.", table: "Settings"),
                    isComingSoon: true,
                    color: .red
                )
            case .batch:
                return Feature(
                    icon: .sfSymbol(.checklist),
                    title: String(localized: "store_feature_batch_title", defaultValue: "Batch Operations", table: "Settings"),
                    description: String(localized: "store_feature_batch_description", defaultValue: "Mark multiple items at once efficiently.", table: "Settings"),
                    isComingSoon: true,
                    color: .indigo
                )
            }
        }
    }
    
    static var features: [Feature] {
        Features.allCases.map(\.feature)
    }
}
