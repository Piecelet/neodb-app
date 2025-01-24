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
}

struct StatusView: View {
    private let logger = Logger.views.status.status
    let status: MastodonStatus
    let mode: StatusViewMode

    @StateObject private var viewModel: StatusViewModel
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @State private var item: (any ItemProtocol)?

    init(status: MastodonStatus, mode: StatusViewMode = .timeline) {
        self.status = status
        self.mode = mode
        _viewModel = StateObject(wrappedValue: StatusViewModel(status: status))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 8) {
                Button {
                    router.navigate(to: .userProfile(id: status.account.id))
                } label: {
                    KFImage(status.account.avatar)
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "person.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.account.displayName ?? "")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("@\(status.account.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text(status.createdAt.formatted)
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

            // Item Preview if available
            if let item = item {
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
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Stats
            HStack {
                Button {
                    router.presentSheet(.replyToStatus(status: status))
                } label: {
                    Label("\(status.repliesCount)", systemImage: "bubble.right")
                }
                        .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation {
                        viewModel.toggleReblog()
                    }
                } label: {
                    Label("\(viewModel.status.reblogsCount)", systemSymbol: .arrow2Squarepath)
                        .foregroundStyle(viewModel.status.reblogged ?? false ? .blue : .secondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                Button {
                    withAnimation {
                        viewModel.toggleFavorite()
                    }
                } label: {
                    Label("\(viewModel.status.favouritesCount)", systemSymbol: viewModel.status.favourited ?? false ? .heartFill : .heart)
                        .foregroundStyle(viewModel.status.favourited ?? false ? .red : .secondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                HStack(spacing: 16) {
                    Button {
                        viewModel.toggleBookmark()
                    } label: {
                        Label("Bookmark", systemSymbol: viewModel.status.bookmarked ?? false ? .bookmarkFill : .bookmark)
                            .labelStyle(.iconOnly)
                            .foregroundStyle(viewModel.status.bookmarked ?? false ? .orange : .secondary)
                    }
                    .padding(.trailing, mode == .detail ? 8 : nil)
                    if let url = URL(string: status.url ?? ""), mode == .timeline {
                        ShareLink(item: url) {
                            Label("Share", systemSymbol: .arrowUpRight)
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .font(.subheadline)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
        .task {
            viewModel.accountsManager = accountsManager
            if !status.content.links.isEmpty {
                for link in status.content.links {
                    if let extractedItem = await NeoDBURL.parseItemURL(
                        link.url, title: link.displayString)
                    {
                        item = extractedItem
                        break
                    }
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
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
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fill)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
