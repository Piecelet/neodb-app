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
    
    let markController: MarkDataController
    let size: ItemMarkSize
    var brief: Bool = false
    var showEditButton: Bool = false

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: size.spacing) {
                    if let rating = markController.ratingGrade {
                        markRatingView(rating)
                        Spacer()
                        Text(markController.createdTime?.relativeFormatted ?? "")
                            .foregroundStyle(.secondary)
                        if let shelfType = markController.shelfType {
                            Image(symbol: shelfType.symbolImage)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        if let shelfType = markController.shelfType {
                            Image(symbol: shelfType.symbolImage)
                                .foregroundStyle(.secondary)
                        }
                        Text(markController.createdTime?.relativeFormatted ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(size.font)
                
                if let comment = markController.commentText, !comment.isEmpty {
                    Text(comment)
                        .font(size.font)
                        .lineLimit(brief ? 2 : nil)
                }
                
                if !markController.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: size.spacing) {
                            ForEach(markController.tags, id: \.self) { tag in
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
            .background(Color.grayBackground)
            .padding(.bottom, (showEditButton && markController.ratingGrade != nil && markController.commentText == nil) ? 20 : 0)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .overlay(alignment: .bottomTrailing) {
            if showEditButton, let mark = markController.mark {
                Button("Edit Mark of \(mark.item.displayTitle ?? mark.item.title ?? "")", systemSymbol: .ellipsis) {
                    router.presentSheet(.editShelfItem(mark: mark))
                    HapticFeedback.impact()
                }
                .buttonStyle(.plain)
                .accentColor(.gray)
                .frame(width: 16, height: 14)
                .labelStyle(.iconOnly)
                .padding(.bottom, 8)
                .padding(.trailing, 12)
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
