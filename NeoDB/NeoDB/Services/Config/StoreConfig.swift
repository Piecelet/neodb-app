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
        let icon: Symbol
        let title: String
        let description: String
        let isComingSoon: Bool
        let color: Color
        
        init(
            icon: Symbol,
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
            icon: .sfSymbol(.sparkles),
            title: "Smooth Experience",
            description: "Enjoy a fluid and responsive interface for browsing and managing your collections.",
            color: .pink
        ),
        Feature(
            icon: .sfSymbol(.infinity),
            title: "Unlimited Collections",
            description: "Mark and collect unlimited books, movies, and music without restrictions.",
            color: .mint
        ),
        Feature(
            icon: .sfSymbol(.magnifyingglassCircle),
            title: "Quick Discovery",
            description: "Instantly search and discover trending books, movies, and music.",
            color: .cyan
        ),
        Feature(
            icon: .sfSymbol(.heart),
            title: "Support Future Development",
            description: "Help a student developer continue building and improving Piecelet.",
            color: .red
        ),
        Feature(
            icon: .sfSymbol(.handRaised),
            title: "Support NeoDB Community",
            description: "Part of the revenue will be donated to support the NeoDB open source project.",
            color: .teal
        ),
        Feature(
            icon: .sfSymbol(.person2),
            title: "Multiple Accounts",
            description: "Connect and switch between multiple NeoDB accounts seamlessly.",
            isComingSoon: true,
            color: .blue
        ),
        Feature(
            icon: .sfSymbol(.arrowTriangle2Circlepath),
            title: "Cross-platform Sync",
            description: "Sync your marks with Trakt and other platforms.",
            isComingSoon: true,
            color: .purple
        ),
        Feature(
            icon: .sfSymbol(.magnifyingglass),
            title: "Enhanced Search",
            description: "Access additional search sources for better results.",
            isComingSoon: true,
            color: .orange
        ),
        Feature(
            icon: .sfSymbol(.arrowLeftArrowRight),
            title: "Quick Actions",
            description: "Quickly search and open items in Douban.",
            isComingSoon: true,
            color: .green
        ),
        Feature(
            icon: .sfSymbol(.bell),
            title: "Series Updates",
            description: "Track and get notified about series updates.",
            isComingSoon: true,
            color: .red
        ),
        Feature(
            icon: .sfSymbol(.checklist),
            title: "Batch Actions",
            description: "Mark multiple items at once efficiently.",
            isComingSoon: true,
            color: .indigo
        )
    ]
}
