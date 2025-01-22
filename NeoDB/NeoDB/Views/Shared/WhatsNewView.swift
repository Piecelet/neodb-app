//
//  WhatsNewView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI
import WhatsNewKit

extension NeoDBApp: WhatsNewCollectionProvider {
    var whatsNewCollection: WhatsNewCollection {
        WhatsNew(
            version: "1.0.0",
            title: "What's New in NeoDB",
            features: [
                .init(
                    image: .init(
                        systemName: "books.vertical.fill",
                        foregroundColor: .orange
                    ),
                    title: "Library Management",
                    subtitle: "Track your books, movies, music, and more in one place"
                ),
                .init(
                    image: .init(
                        systemName: "star.bubble.fill",
                        foregroundColor: .yellow
                    ),
                    title: "Reviews & Ratings",
                    subtitle: "Share your thoughts and discover what others are saying"
                ),
                .init(
                    image: .init(
                        systemName: "person.2.fill",
                        foregroundColor: .blue
                    ),
                    title: "Social Features",
                    subtitle: "Connect with other users and share your collections"
                ),
                .init(
                    image: .init(
                        systemName: "icloud.fill",
                        foregroundColor: .cyan
                    ),
                    title: "Cloud Sync",
                    subtitle: "Your library syncs across all your devices"
                )
            ],
            primaryAction: .init(
                title: "Continue",
                backgroundColor: .accentColor,
                foregroundColor: .white,
                hapticFeedback: .notification(.success)
            )
        )
    }
}

