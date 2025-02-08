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
    @Published private(set) var posts: [NeoDBPost] = []
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
            let endpoint = ItemEndpoint.post(
                uuid: item.uuid, types: [.review, .comment])
            let result = try await accountsManager.currentClient.fetch(
                endpoint, type: PaginatedPostList.self)
            posts = result.data
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
        VStack(alignment: .leading, spacing: 8) {
            Text("item_posts_comments", tableName: "Item")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.posts.isEmpty {
                Text("item_posts_comments_empty", tableName: "Item")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.posts, id: \.id) { post in
                    Button {
                        router.navigate(
                            to: .statusDetailWithStatus(status: post))
                    } label: {
                        StatusView(status: post, mode: .itemPost)
                    }
                    .buttonStyle(.plain)

                    if post.id != viewModel.posts.last?.id {
                        Divider()
                    }
                }
            }
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

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
