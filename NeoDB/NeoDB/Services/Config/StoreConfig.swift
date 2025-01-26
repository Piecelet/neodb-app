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
        enum plus {
            static let entitlementName = "plus"
            static let offeringIdentifier = "plu"
        }

    }
    
    struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let isComingSoon: Bool
        let color: Color
        
        init(
            icon: String,
            title: String,
            description: String,
            isComingSoon: Bool = false,
            color: Color = .accentColor
        ) {
            self.icon = icon
            self.title = title
            self.description = description
            self.isComingSoon = isComingSoon
            self.color = color
        }
    }
    
    static let features: [Feature] = [
        Feature(
            icon: "person.2",
            title: "Multiple Accounts",
            description: "Connect and switch between multiple NeoDB accounts seamlessly.",
            color: .blue
        ),
        Feature(
            icon: "arrow.triangle.2.circlepath",
            title: "Cross-platform Sync",
            description: "Sync your marks with Trakt and other platforms.",
            isComingSoon: true,
            color: .purple
        ),
        Feature(
            icon: "magnifyingglass",
            title: "Enhanced Search",
            description: "Access additional search sources for better results.",
            isComingSoon: true,
            color: .orange
        ),
        Feature(
            icon: "arrow.left.arrow.right",
            title: "Quick Actions",
            description: "Quickly search and open items in Douban.",
            isComingSoon: true,
            color: .green
        ),
        Feature(
            icon: "bell",
            title: "Series Updates",
            description: "Track and get notified about series updates.",
            isComingSoon: true,
            color: .red
        ),
        Feature(
            icon: "checklist",
            title: "Batch Actions",
            description: "Mark multiple items at once efficiently.",
            isComingSoon: true,
            color: .indigo
        )
    ]
}
