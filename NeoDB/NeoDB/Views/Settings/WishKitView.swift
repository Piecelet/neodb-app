//
//  WishKitView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import WishKit

struct WishKitView: View {
    @EnvironmentObject var storeManager: StoreManager

    init() {
        WishKit.configure(with: AppConfig.wishkitApiKey)
        WishKit.theme.primaryColor = .accent
        WishKit.config.allowUndoVote = true
        WishKit.config.expandDescriptionInList = true
        WishKit.config.commentSection = .show
        WishKit.config.buttons.addButton.bottomPadding = .medium
        WishKit.config.statusBadge = .show
        WishKit.config.buttons.doneButton.display = .hide
        WishKit.config.buttons.segmentedControl.display = .show
        WishKit.config.dropShadow = .show
        WishKit.config.localization.featureWishlist = String(localized: "app_feature_requests", table: "Settings")
    }

    var body: some View {
        Group {
            WishKit.FeedbackListView()
        }
        .toolbar(.hidden, for: .tabBar)
        .task {
            switch storeManager.currentSubscriptionType {
            case .monthly:
                WishKit.updateUser(payment: .monthly(1.99))
            case .yearly:
                WishKit.updateUser(payment: .yearly(9.99))
            case .lifetime:
                WishKit.updateUser(payment: .weekly(19.99))
            case .none:
                break
            }
            
            if let appUserID = storeManager.appUserID {
                WishKit.updateUser(customID: appUserID)
            }
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
