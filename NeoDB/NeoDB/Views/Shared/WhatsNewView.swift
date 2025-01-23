//
//  WhatsNewView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI
import WhatsNewKit

private let whatsNewTitle: WhatsNew.Title = .init(
    text: .init("What's New\nin " + AttributedString(
        "Piecelet",
        attributes: AttributeContainer([
            .foregroundColor: Color.accentColor
        ])
    ))
)

private let whatsNewPrimaryAction: WhatsNew.PrimaryAction = .init(
    title: "Continue",
    backgroundColor: Color.accentColor,
    foregroundColor: Color.white,
    hapticFeedback: .notification(.success)
)

extension NeoDBApp: WhatsNewCollectionProvider {
    var whatsNewCollection: WhatsNewCollection {
        WhatsNew(
            version: "0.8",
            title: whatsNewTitle,
            features: [
                .init(
                    image: .init(
                        systemName: "books.vertical",
                        foregroundColor: .blue
                    ),
                    title: "Beautiful New Library",
                    subtitle: "Find and organize your collections with an all-new design"
                ),
                .init(
                    image: .init(
                        systemName: "line.3.horizontal.decrease",
                        foregroundColor: .orange
                    ),
                    title: "Quick Filters",
                    subtitle: "Switch between books, movies, and more with a simple tap"
                ),
                .init(
                    image: .init(
                        systemName: "bolt.square",
                        foregroundColor: .green
                    ),
                    title: "Lightning Fast",
                    subtitle: "Experience faster loading and smoother browsing"
                ),
                .init(
                    image: .init(
                        systemName: "sparkles.rectangle.stack",
                        foregroundColor: .purple
                    ),
                    title: "Delightful Details",
                    subtitle: "Enjoy smooth animations and beautiful item cards"
                )
            ],
            primaryAction: whatsNewPrimaryAction
        )
    }
}

