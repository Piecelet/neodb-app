//
//  StatusView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI

enum StatusViewMode {
    case timeline
    case detail
    case detailWithItem
    case itemPost

    var actions: [StatusActionsView.Action] {
        switch self {
        case .timeline: return [.reply, .reblog, .favorite, .bookmark, .share]
        case .detail, .detailWithItem: return [.reply, .reblog, .favorite, .bookmark]
        case .itemPost: return [.favorite]
        }
    }
}

struct StatusView: View {
    private let logger = Logger.views.status.status
    let status: MastodonStatus
    let mode: StatusViewMode

    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager

    init(status: MastodonStatus, mode: StatusViewMode = .timeline) {
        self.status = status
        self.mode = mode
    }

    var body: some View {
        Group {
            switch mode {
            case .timeline, .detail, .detailWithItem:
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack(alignment: .top, spacing: 8) {
                            Button {
                                router.navigate(
                                    to: .userProfile(id: status.account.id))
                            } label: {
                                AccountAvatarView(account: status.account)

                                AccountNameView(account: status.account)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Text(status.createdAt.relativeFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(status.content.asSafeMarkdownAttributedString)
                            .environment(
                                \.openURL,
                                OpenURLAction { url in
                                    handleURL(url)
                                    return .handled
                                }
                            )
                            .textSelection(.enabled)
                            .lineLimit(mode == .timeline ? 5 : nil)

                        if let item = status.content.links.compactMap(
                            \.neodbItem
                        ).first, mode != .detailWithItem {
                            StatusItemView(item: item)
                        }

                        // Media
                        if !status.mediaAttachments.isEmpty {
                            mediaGrid
                        }

                        // Footer
                        if !status.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(status.tags, id: \.name) { tag in
                                        Text("#\(tag.name)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Color.secondary.opacity(0.1)
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        StatusActionsView(
                            status: status, accountsManager: accountsManager,
                            showActions: mode.actions)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            case .itemPost:
                HStack(alignment: .top, spacing: 8) {
                    Button {
                        router.navigate(
                            to: .userProfile(id: status.account.id))
                    } label: {
                        AccountAvatarView(account: status.account, size: .small)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(
                                    status.account.displayName
                                    ?? status.account.username
                                )
                                .font(.subheadline)
                                .fontWeight(.medium)
                                Spacer()
                                Text(status.createdAt.relativeFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(alignment: .center, spacing: 2) {
                                if let neodbStatusLineAttributedStringWithoutRating = status.content.neodbStatusLineAttributedStringWithoutRating {
                                    Text(neodbStatusLineAttributedStringWithoutRating)
                                        .padding(.top, 2)
                                }
                                if let rating = status.content.rating {
                                    StarView(rating: rating / 2)
                                }
                            }
                            .foregroundStyle(.gray)
                            .font(ItemRatingView.Size.small.font)
                        }

                        Text(status.content.asSafeMarkdownAttributedStringWithoutNeoDBStatus)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        StatusActionsView(
                            status: status, accountsManager: accountsManager,
                            size: .compact,
                            showActions: mode.actions
                        )
                        .padding(.top, 4)
                        .padding(.horizontal, -6)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func handleURL(_ url: URL) {
        URLHandler.handleItemURL(url) { destination in
            if let destination = destination {
                router.navigate(to: destination)
            } else {
                openURL(url)
            }
        }
    }

    @ViewBuilder
    private var mediaGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 4),
            count: min(status.mediaAttachments.count, 2))

        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(status.mediaAttachments) { attachment in
                KFImage(attachment.url)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fill)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
