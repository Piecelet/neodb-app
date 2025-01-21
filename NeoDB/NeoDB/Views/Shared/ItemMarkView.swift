//
//  ItemMarkView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI

enum ItemMarkSize {
    case medium
    case large

    var font: Font {
        switch self {
        case .medium:
            return .footnote
        case .large:
            return .subheadline
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .medium:
            return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .large:
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }
    }
}

struct ItemMarkView: View {
    let mark: MarkSchema
    let size: ItemMarkSize
    var brief: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let rating = mark.ratingGrade {
                    markRatingView(rating)
                    Spacer()
                    Text(mark.createdTime.formatted)
                        .foregroundStyle(.secondary)
                    Image(symbol: mark.shelfType.symbolImage)
                        .foregroundStyle(.secondary)
                } else {
                    Image(symbol: mark.shelfType.symbolImage)
                        .foregroundStyle(.secondary)
                    Text(mark.createdTime.formatted)
                        .foregroundStyle(.secondary)
                }
            }
            .font(size.font)

            if let comment = mark.commentText, !comment.isEmpty {
                Text(comment)
                    .font(size.font)
                    .lineLimit(brief ? 2 : nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(size.padding)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func markRatingView(_ rating: Int) -> some View {
        StarView(rating: Double(rating) / 2)
    }
}
