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

    var spacing: CGFloat {
        switch self {
        case .medium:
            return 4
        case .large:
            return 8
        }
    }
}

struct ItemMarkView: View {
    @EnvironmentObject private var router: Router
    
    let mark: MarkSchema
    let size: ItemMarkSize
    var brief: Bool = false
    var showEditButton: Bool = false

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: size.spacing) {
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
                
                if !mark.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: size.spacing) {
                            ForEach(mark.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(size.padding)
            .background(Color(.systemGray5).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .overlay(alignment: .bottomTrailing) {
            if showEditButton {
                Button("Edit Mark of \(mark.item.displayTitle ?? mark.item.title ?? "")", systemSymbol: .pencil) {
                    router.presentSheet(.editShelfItem(mark: mark))
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                .accentColor(.gray)
                .labelStyle(.iconOnly)
                .padding(.bottom, 6)
                .padding(.trailing, 6)
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func markRatingView(_ rating: Int) -> some View {
        StarView(rating: Double(rating) / 2)
    }
}
