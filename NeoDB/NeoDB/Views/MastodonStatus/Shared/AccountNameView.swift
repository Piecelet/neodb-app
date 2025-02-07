//
//  AccountNameView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct AccountNameView: View {
    enum Size {
        case small
        case regular
        case large

        var nameFont: Font {
            switch self {
            case .small: return .subheadline
            case .regular: return .headline
            case .large: return .largeTitle
            }
        }

        var usernameFont: Font {
            switch self {
            case .small: return .subheadline
            case .regular: return .subheadline
            case .large: return .subheadline
            }
        }
    }

    let account: MastodonAccount?
    let user: User?
    var showUsername: Bool = true
    var alignment: HorizontalAlignment = .leading
    var size: Size = .regular
    
    init(account: MastodonAccount, showUsername: Bool = true, size: Size = .regular, alignment: HorizontalAlignment = .leading) {
        self.account = account
        self.user = nil
        self.showUsername = showUsername
        self.alignment = alignment
        self.size = size
    }
    
    init(user: User, showUsername: Bool = true, size: Size = .regular, alignment: HorizontalAlignment = .leading) {
        self.account = nil
        self.user = user
        self.showUsername = showUsername
        self.alignment = alignment
        self.size = size
    }
    
    var displayName: String {
        if let account = account {
            return account.displayName ?? account.username
        }
        return user?.displayName ?? user?.username ?? ""
    }
    
    var username: String {
        if let account = account {
            return "@\(account.acct)"
        }
        return user?.username ?? ""
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(displayName)
                .font(size.nameFont)
                .foregroundStyle(.primary)
            
            if showUsername {
                Text(username)
                    .font(size.usernameFont)
                    .foregroundStyle(.secondary)
            }
        }
        .enableInjection()
    }
    
    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
} 
