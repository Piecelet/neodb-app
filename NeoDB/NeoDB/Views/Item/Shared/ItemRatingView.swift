//
//  ItemRatingView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI

struct StarView: View {
    let rating: Double
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: -1) {
            ForEach(0..<maxRating, id: \.self) { index in
                let fillLevel = rating - Double(index)
                Image(symbol: starType(for: fillLevel))
                    .foregroundStyle(.ratingPrimary)
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func starType(for fillLevel: Double) -> Symbol {
        if fillLevel >= 1 {
            return .sfSymbol(.starFill)
        } else if fillLevel >= 0.5 {
            return .sfSymbol(.starLeadinghalfFilled)
        } else {
            return .sfSymbol(.star)
        }
    }
}

struct ItemRatingView: View {
    enum Size {
        case small
        case medium
        case large

        var font: Font {
            switch self {
            case .small:
                return .footnote
            case .medium:
                return .subheadline
            case .large:
                return .subheadline
            }
        }
        
        var weight: Font.Weight? {
            switch self {
            default:
                return nil
            }
        }
    }
    
    let item: (any ItemProtocol)?
    let size: Size
    var hideRatingCount: Bool = false
    var showFullStar: Bool = false
    var showCategory: Bool = false

    var body: some View {
        Group {
            if let item = item {
                HStack(spacing: 4) {
                    if let rating = item.rating {
                        Group {
                            if showFullStar {
                                StarView(rating: rating / 2)
                            } else {
                                Image(systemName: "star.fill")
                            }
                        }
                        .foregroundStyle(.ratingPrimary)
                        Text(String(format: "%.1f", rating))
                        if let count = item.ratingCount, !hideRatingCount {
                            Text("(\(count))")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.gray.opacity(0.5))
                        Text(size == .large ? String(localized: "item_rating_none", table: "Item") : String(localized: "item_rating_na", table: "Item"))
                            .foregroundStyle(.secondary)
                    }
                    if showCategory {
                        Text("/")
                            .foregroundStyle(.secondary)
                        Text(item.category.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(size.font)
                .fontWeight(size.weight)
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
