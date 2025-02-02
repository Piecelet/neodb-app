//
//  ItemCoverView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import Kingfisher
import SwiftUI

enum ItemCoverSize {
    case small  // 64pt height, 4pt corner radius
    case medium  // 90pt height, 4pt corner radius
    case large  // 140pt height, 8pt corner radius

    var height: CGFloat {
        switch self {
        case .small:
            return 64
        case .medium:
            return 90
        case .large:
            return 140
        }
    }

    var width: CGFloat? {
        switch self {
        case .large:
            return 128
        default:
            return nil
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small, .medium:
            return 4
        case .large:
            return 4
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small:
            return 16
        case .medium:
            return 24
        case .large:
            return 48
        }
    }
}

enum ItemCoverAlignment {
    case horizontal
    case vertical
}

struct ItemCoverView: View {
    let item: (any ItemProtocol)?
    let size: ItemCoverSize
    var alignment: ItemCoverAlignment = .horizontal
    var showSkeleton: Bool = false

    var body: some View {
        Group {
            if let item = item {
                KFImage(item.coverImageUrl)
                    .placeholder {
                        placeholderView
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                    )
                    .frame(
                        maxWidth: alignment == .horizontal ? size.height * AppConfig.defaultItemCoverRatio : nil,
                        maxHeight: alignment == .vertical ? size.height : nil,
                        alignment: size == .large ? .topLeading : .center
                    )
                    .overlay {
                        if showSkeleton {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    ProgressView()
                                }
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: size.cornerRadius))
                        }
                    }
            } else {
                placeholderView
            }
        }
        .enableInjection()
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(item?.category.placeholderRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .frame(
                width: alignment == .horizontal ? size.height * AppConfig.defaultItemCoverRatio : nil,
                height: alignment == .vertical ? size.height : nil,
                alignment: .topLeading
            )
            .fixedSize(horizontal: false, vertical: false)
            .overlay {
                if let item = item {
                    Image(symbol: item.category.symbolImageFill)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: size.fontSize))
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
