//
//  ItemCoverView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI
import Kingfisher

enum ItemCoverSize {
    case small
    case medium
    
    var height: CGFloat {
        switch self {
        case .small:
            return 64
        case .medium:
            return 140
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 4
        case .medium:
            return 8
        }
    }
}

struct ItemCoverView: View {
    let item: (any ItemProtocol)?
    let size: ItemCoverSize
    var showSkeleton: Bool = false
    
    var body: some View {
        if let item = item {
            KFImage(item.coverImageUrl)
                .placeholder {
                    placeholderView
                }
                .onFailure { _ in
                    placeholderView
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
                .overlay {
                    if showSkeleton {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(2/3, contentMode: .fit)
            .frame(height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay {
                if let item = item {
                    Image(symbol: item.category.symbolImage)
                }
            }
    }
}
