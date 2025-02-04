//
//  ItemViewPosts.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/4/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import OSLog

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
            let endpoint = ItemEndpoint.post(uuid: item.uuid, types: [.review, .comment])
            let result = try await accountsManager.currentClient.fetch(endpoint, type: PaginatedPostList.self)
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
    
    init(item: any ItemProtocol) {
        self._viewModel = StateObject(wrappedValue: ItemViewPostsViewModel(item: item))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("item_posts", tableName: "Item")
                .font(.headline)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.posts.isEmpty {
                Text("item_no_posts", tableName: "Item")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.posts, id: \.id) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(post.account.displayName ?? post.account.username)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text(post.createdAt.relativeFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(post.content.asSafeMarkdownAttributedString)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    
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
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { _ in
            Button("OK", role: .cancel) {}
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

