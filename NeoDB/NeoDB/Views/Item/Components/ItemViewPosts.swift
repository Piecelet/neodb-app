//
//  ItemViewPosts.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI

@MainActor
final class ItemViewPostsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.views.item

    // MARK: - Published Properties
    @Published private(set) var reviews: [NeoDBPost] = []
    @Published private(set) var comments: [NeoDBPost] = []
    @Published private(set) var isLoading = false
    @Published var error: Error?
    @Published var showError = false

    // MARK: - Properties
    var accountsManager: AppAccountsManager?
    let item: any ItemProtocol

    init(item: any ItemProtocol) {
        self.item = item
    }

    func loadPosts() async {
        guard let accountsManager = accountsManager else {
            logger.debug("No accountsManager available")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let reviewEndpoint = ItemEndpoint.post(
                uuid: item.uuid, types: [.review])
            let reviewResult = try await accountsManager.currentClient.fetch(
                reviewEndpoint, type: PaginatedPostList.self)
            reviews = reviewResult.data

            let commentEndpoint = ItemEndpoint.post(
                uuid: item.uuid, types: [.comment])
            let commentResult = try await accountsManager.currentClient.fetch(
                commentEndpoint, type: PaginatedPostList.self)
            comments = commentResult.data
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to load posts: \(error.localizedDescription)")
        }
    }
}

struct ItemViewPosts: View {
    @StateObject private var viewModel: ItemViewPostsViewModel
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router

    init(item: any ItemProtocol) {
        self._viewModel = StateObject(
            wrappedValue: ItemViewPostsViewModel(item: item))
    }

    var body: some View {
        Group {
            commentsView
            reviewsView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadPosts()
        }
        .alert(
            "Error", isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        }
        .enableInjection()
    }

    var commentsView: some View {
        Group {
            Divider()
                .padding(.vertical)
            VStack(alignment: .leading, spacing: 8) {
                Text("item_posts_comments", tableName: "Item")
                    .font(.headline)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if viewModel.comments.isEmpty {
                    Text("item_posts_comments_empty", tableName: "Item")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.comments, id: \.id) { comment in
                        Button {
                            router.navigate(
                                to: .statusDetailWithStatusAndItem(
                                    status: comment, item: viewModel.item))
                        } label: {
                            StatusView(status: comment, mode: .itemPost)
                        }
                        .buttonStyle(.plain)

                        if comment.id != viewModel.comments.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    var reviewsView: some View {
        Group {
            Divider()
                .padding(.vertical)
            VStack(alignment: .leading, spacing: 8) {
                Text("item_posts_reviews", tableName: "Item")
                    .font(.headline)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if viewModel.reviews.isEmpty {
                    Text("item_posts_reviews_empty", tableName: "Item")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.reviews, id: \.id) { review in
                        Button {
                            router.navigate(
                                to: .statusDetailWithStatusAndItem(
                                    status: review, item: viewModel.item))
                        } label: {
                            StatusView(status: review, mode: .itemPost)
                        }
                        .buttonStyle(.plain)

                        if review.id != viewModel.reviews.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
