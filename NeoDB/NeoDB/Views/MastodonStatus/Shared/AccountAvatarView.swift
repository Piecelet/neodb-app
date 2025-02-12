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
            case .small: 36
            case .regular: 44
            case .large: 80
            }
        }

        var symbolScale: CGFloat {
            switch self {
            case .small: 0.5
            case .regular: 0.5
            case .large: 0.5
            }
        }
    }

    let account: MastodonAccount?
    let user: User?
    var size: Size = .regular
    var showPlaceholder: Bool = true

    init(
        account: MastodonAccount, size: Size = .regular,
        showPlaceholder: Bool = true
    ) {
        self.account = account
        self.user = nil
        self.size = size
        self.showPlaceholder = showPlaceholder
    }

    init(user: User, size: Size = .regular, showPlaceholder: Bool = true) {
        self.account = nil
        self.user = user
        self.size = size
        self.showPlaceholder = showPlaceholder
    }

    private var shouldShowAvatar: Bool {
        if let account = account {
            return account.haveAvatar
        }
        if avatarURL?.host?.contains("piecelet.internal/placeholder") == true {
            return false
        }
        return user?.avatar != nil
    }

    private var avatarURL: URL? {
        if let account = account {
            return account.avatar
        }
        return user?.avatar
    }

    var body: some View {
        Group {
            if shouldShowAvatar, let avatar = avatarURL {
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
