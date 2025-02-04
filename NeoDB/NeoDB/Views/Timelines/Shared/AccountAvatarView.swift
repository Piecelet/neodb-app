//
//  AccountAvatarView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Kingfisher
import SwiftUI

struct AccountAvatarView: View {
    enum Size {
        case small
        case regular
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: 32
            case .regular: 44
            case .large: 80
            }
        }
        
        var symbolScale: CGFloat {
            switch self {
            case .small: 0.6
            case .regular: 0.5
            case .large: 0.8
            }
        }
    }
    
    let account: MastodonAccount
    var size: Size = .regular
    var showPlaceholder: Bool = true
    
    private var shouldShowAvatar: Bool {
        return account.haveAvatar
    }
    
    var body: some View {
        Group {
            if shouldShowAvatar, let avatar = account.avatar {
                KFImage(avatar)
                    .placeholder {
                        placeholderView
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(Circle())
            } else if showPlaceholder {
                placeholderView
            }
        }
        .enableInjection()
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(Color.grayBackground)
            .frame(width: size.dimension, height: size.dimension)
            .overlay {
                Image(systemSymbol: .personFill)
                    .font(.system(size: size.dimension * size.symbolScale))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
    }
    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
