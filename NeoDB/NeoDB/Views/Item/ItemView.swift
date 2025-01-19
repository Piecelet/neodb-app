//
//  ItemView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import ExpandableText
import Kingfisher
import SwiftUI

struct ItemView: View {
    @StateObject private var viewModel: ItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.openURL) private var openURL

    let id: String
    let category: ItemCategory
    private let initialItem: (any ItemProtocol)?

    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.initialItem = item
        self._viewModel = StateObject(
            wrappedValue: ItemViewModel(initialItem: item))
    }

    var body: some View {
        ItemContent(
            state: viewModel.state,
            header: ItemHeaderView(
                title: viewModel.displayTitle,
                coverURL: viewModel.coverImageURL,
                rating: viewModel.rating,
                ratingCount: viewModel.ratingCount,
                metadata: viewModel.metadata
            ),
            description: viewModel.description,
            actions: ItemActionsView(isRefreshing: viewModel.isRefreshing),
            isRefreshing: viewModel.isRefreshing
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .refreshable {
            await viewModel.loadItemDetail(
                id: itemUUID, category: category, refresh: true)
        }
        .alert(
            "Error", isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadItemDetail(id: itemUUID, category: category)
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .environmentObject(viewModel)
        .enableInjection()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                if let resources = viewModel.item?.externalResources,
                    !resources.isEmpty
                {
                    Menu {
                        ForEach(resources, id: \.url) { resource in
                            Button(role: .none) {
                                openURL(resource.url)
                            } label: {
                                Label(resource.name, systemImage: resource.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "link")
                    }
                }

                if let url = viewModel.shareURL {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var itemUUID: String {
        URL(string: id)?.lastPathComponent ?? id
    }
}

// MARK: - Content Views
private struct ItemContent: View {
    let state: ItemState
    let header: ItemHeaderView
    let description: String
    let actions: ItemActionsView
    let isRefreshing: Bool

    var body: some View {
        ScrollView {
            switch state {
            case .loading:
                loadingView
            case .loaded:
                loadedView
            case .error:
                errorView
            }
        }
        .enableInjection()
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var loadedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .overlay(alignment: .topTrailing) {
                    if isRefreshing {
                        ProgressView()
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding([.top, .trailing], 8)
                    }
                }

            Divider()
                .padding(.vertical)

            if !description.isEmpty {
                ItemDescriptionView(description: description)

                Divider()
                    .padding(.vertical)
            }

            actions
                .padding(.horizontal)
        }
    }

    private var errorView: some View {
        EmptyStateView(
            "Item Not Found",
            systemImage: "exclamationmark.triangle",
            description: Text(
                "The requested item could not be found or has been removed."
            )
        )
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

// MARK: - Header View
private struct ItemHeaderView: View {
    let title: String
    let coverURL: URL?
    let rating: String
    let ratingCount: String
    let metadata: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                coverImageView
                itemDetailsView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .enableInjection()
    }

    private var coverImageView: some View {
        KFImage(coverURL)
            .placeholder {
                placeholderView
            }
            .onFailure { _ in
                placeholderView
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(2 / 3, contentMode: .fit)
            .frame(width: 120)
    }

    private var itemDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(3)

            if !rating.isEmpty {
                ratingView
            }

            if !metadata.isEmpty {
                Text(metadata.joined(separator: " / "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var ratingView: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(rating)
            Text("(\(ratingCount))")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    ItemHeaderView(
        title:
            "Sample Book Title That is Very Long and Might Need Multiple Lines",
        coverURL: nil,
        rating: "4.5",
        ratingCount: "123",
        metadata: [
            "John Doe",
            "2024",
            "978-3-16-148410-0",
        ]
    )
}

// MARK: - Description View
private struct ItemDescriptionView: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            ExpandableText(description)
                .font(.callout)
                .foregroundStyle(.black.opacity(0.8))
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Actions View
private struct ItemActionsView: View {
    @EnvironmentObject private var viewModel: ItemViewModel
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router

    let isRefreshing: Bool

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isMarkLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let mark = viewModel.mark {
                markInfoView(mark)
            }

            actionButton
        }
        .onChange(of: isRefreshing) { newValue in
            if newValue {
                viewModel.refresh()
            }
        }
        .enableInjection()
    }

    private func markInfoView(_ mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let rating = mark.ratingGrade {
                    ratingView(rating)
                }
                if mark.ratingGrade != nil {
                    Text("・")
                        .foregroundStyle(.secondary)
                }
                Text(mark.shelfType.displayName)
                    .foregroundStyle(.primary)
                Text("・")
                    .foregroundStyle(.secondary)
                Text(mark.createdTime.formatted)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            if let comment = mark.commentText, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func ratingView(_ rating: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text("\(rating)")
                .foregroundStyle(.primary)
            Text("/10")
                .foregroundStyle(.secondary)
        }
    }

    private var actionButton: some View {
        Button {
            if let item = viewModel.item {
                if let mark = viewModel.mark {
                    router.presentedSheet = .editShelfItem(mark: mark)
                } else {
                    router.presentedSheet = .addToShelf(item: item)
                }
            }
        } label: {
            HStack {
                Image(
                    systemName: viewModel.shelfType == nil
                        ? "plus" : "checkmark")
                if let shelfType = viewModel.shelfType {
                    Text(shelfType.displayName)
                } else {
                    Text("Add to Shelf")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isMarkLoading)
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ItemView(
            id: "preview_id",
            category: .book
        )
        .environmentObject(Router())
        .environmentObject(AppAccountsManager())
    }
}
