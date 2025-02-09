//
//  ItemViewPosts.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI

struct ItemViewPostsState: Equatable {
    var posts: [NeoDBPost] = []
    var isInited = false
    var isLoading = false {
        didSet {
            if isLoading {
                error = nil
            }
        }
    }
    var error: Error?
    var lastRefreshTime: Date?
    
    static func == (lhs: ItemViewPostsState, rhs: ItemViewPostsState) -> Bool {
        lhs.posts.map(\.id) == rhs.posts.map(\.id) &&
        lhs.isLoading == rhs.isLoading &&
        lhs.isInited == rhs.isInited &&
        lhs.lastRefreshTime == rhs.lastRefreshTime
    }
}

@MainActor
final class ItemViewPostsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger.views.item
    private let cacheService = CacheService.shared

    // MARK: - Published Properties
    @Published private(set) var reviewsState = ItemViewPostsState()
    @Published private(set) var commentsState = ItemViewPostsState()
    @Published var error: Error?
    @Published var showError = false

    var reviews: [NeoDBPost] { reviewsState.posts }
    var comments: [NeoDBPost] { commentsState.posts }
    var isLoading: Bool { reviewsState.isLoading || commentsState.isLoading }

    // MARK: - Properties
    var accountsManager: AppAccountsManager?
    let item: any ItemProtocol

    init(item: any ItemProtocol) {
        self.item = item
    }

    private func loadCache() async {
        // Try loading from cache first
        if let cachedReviews = try? await cacheService.retrieveItemPosts(id: item.id, type: .review) {
            reviewsState.posts = cachedReviews
            reviewsState.lastRefreshTime = Date()
            reviewsState.isInited = true
            logger.debug("Loaded \(cachedReviews.count) reviews from cache")
        }
        
        if let cachedComments = try? await cacheService.retrieveItemPosts(id: item.id, type: .comment) {
            commentsState.posts = cachedComments
            commentsState.lastRefreshTime = Date()
            commentsState.isInited = true
            logger.debug("Loaded \(cachedComments.count) comments from cache")
        }
    }
    
    private func fetchReviews() async throws -> [NeoDBPost] {
        guard let accountsManager = accountsManager else {
            throw NetworkError.unauthorized
        }
        
        let reviewEndpoint = ItemEndpoint.post(uuid: item.uuid, types: [.review])
        let reviewResult = try await accountsManager.currentClient.fetch(reviewEndpoint, type: PaginatedPostList.self)
        
        // Cache the new reviews
        try? await cacheService.cacheItemPosts(reviewResult.data, id: item.id, type: .review)
        logger.debug("Cached \(reviewResult.data.count) reviews")
        
        return reviewResult.data
    }
    
    private func fetchComments() async throws -> [NeoDBPost] {
        guard let accountsManager = accountsManager else {
            throw NetworkError.unauthorized
        }
        
        let commentEndpoint = ItemEndpoint.post(uuid: item.uuid, types: [.comment])
        let commentResult = try await accountsManager.currentClient.fetch(commentEndpoint, type: PaginatedPostList.self)
        
        // Cache the new comments
        try? await cacheService.cacheItemPosts(commentResult.data, id: item.id, type: .comment)
        logger.debug("Cached \(commentResult.data.count) comments")
        
        return commentResult.data
    }

    func loadPosts() async {
        guard accountsManager != nil else {
            logger.debug("No accountsManager available")
            return
        }

        reviewsState.isLoading = true
        commentsState.isLoading = true
        
        // Load cache first
        await loadCache()
        
        // Fetch fresh data from network concurrently
        do {
            async let reviewsResult = fetchReviews()
            async let commentsResult = fetchComments()
            
            // Wait for both requests to complete
            let (newReviews, newComments) = try await (reviewsResult, commentsResult)
            
            // Update UI with new data
            reviewsState.posts = newReviews
            reviewsState.lastRefreshTime = Date()
            reviewsState.isInited = true
            
            commentsState.posts = newComments
            commentsState.lastRefreshTime = Date()
            commentsState.isInited = true
            
        } catch {
            self.error = error
            if let error = error as? NetworkError {
                switch error {
                case .cancelled:
                    break
                default:
                    self.showError = true
                }
            }
            reviewsState.error = error
            commentsState.error = error
            logger.error("Failed to load posts: \(error.localizedDescription)")
        }
        
        reviewsState.isLoading = false
        commentsState.isLoading = false
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
        postsView(
            state: viewModel.commentsState,
            title: String(localized: "item_posts_comments", defaultValue: "Comments", table: "Item", comment: "Item Detail Comments"),
            emptyText: String(localized: "item_posts_comments_empty", defaultValue: "No comments", table: "Item", comment: "Item Detail Comments Empty")
        )
    }

    var reviewsView: some View {
        postsView(
            state: viewModel.reviewsState,
            title: String(localized: "item_posts_reviews", defaultValue: "Reviews", table: "Item", comment: "Item Detail Reviews"),
            emptyText: String(localized: "item_posts_reviews_empty", defaultValue: "No reviews", table: "Item", comment: "Item Detail Reviews Empty")
        )
    }

    func postsView(state: ItemViewPostsState, title: String, emptyText: String) -> some View {
        Group {
            Divider()
                .padding(.vertical)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                if !state.posts.isEmpty {
                    ForEach(state.posts, id: \.id) { post in
                        Button {
                            router.navigate(
                                to: .statusDetailWithStatusAndItem(
                                    status: post, item: viewModel.item))
                        } label: {
                            StatusView(status: post, mode: .itemPost)
                        }
                        .buttonStyle(.plain)

                        if post.id != state.posts.last?.id {
                            Divider()
                        }
                    }
                } else if state.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                } else if state.error != nil {
                    Text(state.error?.localizedDescription ?? "Unknown error")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
