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
    case horizontal  // 固定宽度，高度自适应
    case vertical   // 固定高度，宽度自适应
    case fixed      // 固定宽高，使用placeholderRatio
}

struct ItemCoverView: View {
    let item: (any ItemProtocol)?
    let size: ItemCoverSize
    var alignment: ItemCoverAlignment = .horizontal
    var showSkeleton: Bool = false
    
    private var frameSize: (width: CGFloat?, height: CGFloat?) {
        switch alignment {
        case .horizontal:
            return (width: size.height * AppConfig.defaultItemCoverRatio, height: nil)
        case .vertical:
            return (width: nil, height: size.height)
        case .fixed:
            let resizedWidth = size.height * AppConfig.defaultItemCoverRatio
            let ratio = item?.category.placeholderRatio ?? AppConfig.defaultItemCoverRatio
            return (width: resizedWidth, height: resizedWidth / ratio)
        }
    }

    var body: some View {
        Group {
            if let item = item,
                let coverImageUrl = item.coverImageUrl,
                !coverImageUrl.absoluteString.contains("piecelet.internal/placeholder") {
                KFImage(coverImageUrl)
                    .placeholder {
                        placeholderView
                    }
                    .resizable()
                    .aspectRatio(contentMode: alignment == .fixed ? .fill : .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: size.cornerRadius)
                    )
                    .frame(
                        width: frameSize.width,
                        height: frameSize.height
                    )
                    .clipped()
                    .clipShape(
                        RoundedRectangle(cornerRadius: size.cornerRadius)
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
            .aspectRatio(item?.category.placeholderRatio, contentMode: .fill)
            .frame(
                width: frameSize.width,
                height: frameSize.height
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
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
