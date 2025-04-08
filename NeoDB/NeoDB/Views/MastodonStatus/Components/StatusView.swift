//
//  StatusView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI
import WrappingHStack

enum StatusViewMode {
    case timeline
    case timelineWithItem
    case detail
    case detailWithItem
    case itemPost

    var actions: [StatusActionsView.Action] {
        switch self {
        case .timeline, .timelineWithItem: return [.reply, .reblog, .favorite, .bookmark, .share]
        case .detail, .detailWithItem:
            return [.reply, .reblog, .favorite, .bookmark]
        case .itemPost: return [.favorite]
        }
    }
}

struct StatusView: View {
    private let logger = Logger.views.status.status
    let status: MastodonStatus
    let mode: StatusViewMode

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager

    init(status: MastodonStatus, mode: StatusViewMode = .timeline) {
        self.status = status
        self.mode = mode
    }

    var content: AttributedString {
        switch mode {
        case .timelineWithItem, .itemPost, .detailWithItem:
            return status.content
                .asSafeMarkdownAttributedStringWithoutNeoDBStatus
        case .timeline, .detail:
            return status.content.asSafeMarkdownAttributedString
        }
    }

    var isTimeline: Bool {
        mode == .timeline || mode == .timelineWithItem
    }

    var body: some View {
        Group {
            switch mode {
            case .timeline, .timelineWithItem, .detail, .detailWithItem:
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack(alignment: .top, spacing: 8) {
                            Button {
                                router.navigate(
                                    to: .userProfile(id: status.account.id))
                                TelemetryService.shared.trackMastodonProfileView()
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

                        if mode == .detailWithItem || mode == .timelineWithItem {
                            WrappingHStack(alignment: .leading, spacing: .constant(4), lineSpacing: 0) {
                                if let
                                    neodbStatusLineAttributedStringWithoutRating =
                                    status.content
                                    .neodbStatusLineAttributedStringWithoutRating
                                {
                                    Text(
                                        neodbStatusLineAttributedStringWithoutRating
                                    )
                                    .lineLimit(isTimeline ? 5 : nil)
                                    .padding(.top, 2)
                                }
                                if let rating = status.content.rating {
                                    StarView(rating: rating / 2)
                                }
                            }
                            .foregroundStyle(.gray)
                            .font(ItemRatingView.Size.small.font)
                        }

                        if !content.characters.isEmpty {
                            Text(content)
                                .environment(
                                    \.openURL,
                                    OpenURLAction { url in
                                        handleURL(url)
                                        return .handled
                                    }
                                )
                                .textSelection(.enabled)
                                .lineLimit(isTimeline ? 5 : nil)
                        }

                        if let item = status.content.links.lazy.compactMap(
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
                        TelemetryService.shared.trackMastodonProfileView()
                    } label: {
                        AccountAvatarView(account: status.account, size: .small)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Button {
                                    router.navigate(
                                        to: .userProfile(id: status.account.id))
                                    TelemetryService.shared.trackMastodonProfileView()
                                } label: {
                                    Text(
                                        status.account.displayName
                                            ?? status.account.username
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                }
                                Spacer()
                                Text(status.createdAt.relativeFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            WrappingHStack(alignment: .leading, spacing: .dynamic(minSpacing: 4), lineSpacing: 0) {
                                if let
                                    neodbStatusLineAttributedStringWithoutRating =
                                    status.content
                                    .neodbStatusLineAttributedStringWithoutRating
                                {
                                    Text(
                                        neodbStatusLineAttributedStringWithoutRating
                                    )
                                    .padding(.top, 2)
                                }
                                if let rating = status.content.rating {
                                    StarView(rating: rating / 2)
                                        .padding(.vertical, 2)
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(.gray)
                            .font(ItemRatingView.Size.small.font)
                        }

                        Text(
                            status.content
                                .asSafeMarkdownAttributedStringWithoutNeoDBStatus
                        )
                        .font(.callout)

                        StatusActionsView(
                            status: status, accountsManager: accountsManager,
                            size: .compact,
                            showActions: mode.actions
                        )
                        .padding(.top, 4)
                        .padding(.horizontal, -6)
                    }
                }
                .contentShape(Rectangle())
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
                OpenURLAction(handler: { url in
                    return .systemAction(url)
                }).callAsFunction(url)
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
