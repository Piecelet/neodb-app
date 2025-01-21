//
//  ItemRatingView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI

enum ItemRatingSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small:
            return .caption
        case .medium:
            return .subheadline
        case .large:
            return .subheadline
        }
    }
}

struct ItemRatingView: View {
    let item: (any ItemProtocol)?
    let size: ItemRatingSize
    var hideRatingCount: Bool = false

    var body: some View {
        Group {
            if let item = item {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(
                            item.rating == nil
                                ? .gray.opacity(0.5) : .orange.opacity(0.8))
                    if let rating = item.rating {
                        Text(String(format: "%.1f", rating))
                        if let count = item.ratingCount, !hideRatingCount {
                            Text("(\(count))")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(size == .large ? "No Ratings" : "N/A")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(size.font)
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
