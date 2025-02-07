//
//  StatusActionsView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct StatusActionsView: View {
    enum Size {
        case regular
    }

    enum Action {
        case reply
        case reblog
        case favorite
        case bookmark
        case share
    }

    private let statusDataControllerProvider = StatusDataControllerProvider
        .shared

    let status: MastodonStatus
    let accountsManager: AppAccountsManager
    @ObservedObject private var dataController: StatusDataController
    let size: Size

    var showActions: [Action] = [.reply, .reblog, .favorite, .bookmark, .share]

    @EnvironmentObject private var router: Router

    init(
        status: MastodonStatus, accountsManager: AppAccountsManager,
        size: Size = .regular,
        showActions: [Action] = [.reply, .reblog, .favorite, .bookmark, .share]
    ) {
        self.status = status
        self.accountsManager = accountsManager
        self.size = size
        self.showActions = showActions
        self.dataController = statusDataControllerProvider.dataController(
            for: status,
            accountsManager: accountsManager
        )
    }

    var body: some View {

        // Stats
        HStack {
            if showActions.contains(.reply) {
                Button {
                    HapticService.shared.selection()
                    router.presentSheet(.replyToStatus(status: status))
                } label: {
                    Label(
                        "\(dataController.repliesCount)",
                        systemImage: "bubble.right"
                    )
                    .padding(6)
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if showActions.contains(.reblog) {
                Button {
                    HapticService.shared.impact(.medium)
                    Task { @MainActor in
                        await dataController.toggleReblog(
                            remoteStatus: status.id)
                    }
                } label: {
                    Label(
                        "\(dataController.reblogsCount)",
                        systemSymbol: .arrow2Squarepath
                    )
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(
                        dataController.isReblogged
                            ? .blue : .secondary
                    )
                    .padding(6)
                    .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            if showActions.contains(.favorite) {
                Button {
                    HapticService.shared.impact(.medium)
                    Task { @MainActor in
                        await dataController.toggleFavorite(
                            remoteStatus: status.id)
                    }
                } label: {
                    Label(
                        "\(dataController.favoritesCount)",
                        systemSymbol: dataController.isFavorited
                            ? .heartFill : .heart
                    )
                    .padding(6)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(
                        dataController.isFavorited
                            ? .red : .secondary
                    )
                    .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            HStack(spacing: 10) {
                if showActions.contains(.bookmark) {
                    Button {
                        HapticService.shared.impact(.medium)
                        Task {
                            await dataController.toggleBookmark(
                                remoteStatus: status.id)
                        }
                    } label: {
                        Label(
                            "Bookmark",
                            systemSymbol: dataController.isBookmarked
                                ? .bookmarkFill : .bookmark
                        )
                        .padding(6)
                        .foregroundStyle(
                            dataController.isBookmarked
                                ? .orange : .secondary)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .padding(.trailing, !showActions.contains(.share) ? 8 : nil)
                }
                if showActions.contains(.share) {
                    ShareLink(item: URL(string: status.url ?? "")!) {
                        Label("Share", systemSymbol: .arrowUpRight)
                    }
                    .padding(6)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticService.shared.impact(.medium)
                    })
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, -6)
        .padding(.horizontal)
        .font(.subheadline)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
