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
        case multipleAccounts
        case supportDev
        case supportCommunity
        case sync
        case search
        case actions
        case updates
        case batch
        
        var feature: Feature {
            switch self {
            case .smooth:
                return Feature(
                    icon: .sfSymbol(.sparkles),
                    title: String(localized: "store_feature_smooth_title", table: "Settings"),
                    description: String(localized: "store_feature_smooth_description", table: "Settings"),
                    isFree: true,
                    color: .pink
                )
            case .unlimited:
                return Feature(
                    icon: .sfSymbol(.infinity),
                    title: String(localized: "store_feature_unlimited_title", table: "Settings"),
                    description: String(localized: "store_feature_unlimited_description", table: "Settings"),
                    isFree: true,
                    color: .mint
                )
            case .discovery:
                return Feature(
                    icon: .sfSymbol(.magnifyingglassCircle),
                    title: String(localized: "store_feature_discovery_title", table: "Settings"),
                    description: String(localized: "store_feature_discovery_description", table: "Settings"),
                    isFree: true,
                    color: .cyan
                )
            case .multipleAccounts:
                return Feature(
                    icon: .sfSymbol(.personCropCircle),
                    title: String(localized: "store_feature_accounts_title", table: "Settings"),
                    description: String(localized: "store_feature_accounts_description", table: "Settings"),
                    color: .blue
                )
            case .supportDev:
                return Feature(
                    icon: .sfSymbol(.heart),
                    title: String(localized: "store_feature_support_dev_title", table: "Settings"),
                    description: String(localized: "store_feature_support_dev_description", table: "Settings"),
                    color: .red
                )
            case .supportCommunity:
                return Feature(
                    icon: .sfSymbol(.handRaised),
                    title: String(localized: "store_feature_support_community_title", table: "Settings"),
                    description: String(localized: "store_feature_support_community_description", table: "Settings"),
                    color: .teal
                )
            case .sync:
                return Feature(
                    icon: .sfSymbol(.arrowTriangle2Circlepath),
                    title: String(localized: "store_feature_sync_title", table: "Settings"),
                    description: String(localized: "store_feature_sync_description", table: "Settings"),
                    isComingSoon: true,
                    color: .purple
                )
            case .search:
                return Feature(
                    icon: .sfSymbol(.magnifyingglass),
                    title: String(localized: "store_feature_search_title", table: "Settings"),
                    description: String(localized: "store_feature_search_description", table: "Settings"),
                    isComingSoon: true,
                    color: .orange
                )
            case .actions:
                return Feature(
                    icon: .sfSymbol(.arrowLeftArrowRight),
                    title: String(localized: "store_feature_actions_title", table: "Settings"),
                    description: String(localized: "store_feature_actions_description", table: "Settings"),
                    isComingSoon: true,
                    color: .green
                )
            case .updates:
                return Feature(
                    icon: .sfSymbol(.bell),
                    title: String(localized: "store_feature_updates_title", table: "Settings"),
                    description: String(localized: "store_feature_updates_description", table: "Settings"),
                    isComingSoon: true,
                    color: .red
                )
            case .batch:
                return Feature(
                    icon: .sfSymbol(.checklist),
                    title: String(localized: "store_feature_batch_title", table: "Settings"),
                    description: String(localized: "store_feature_batch_description", table: "Settings"),
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
