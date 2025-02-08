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
    // MARK: - Properties
    @StateObject private var viewModel: ItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.openURL) private var openURL

    let id: String
    let category: ItemCategory
    private let initialItem: (any ItemProtocol)?

    // MARK: - Initialization
    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.initialItem = item
        self._viewModel = StateObject(
            wrappedValue: ItemViewModel(initialItem: item))
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loading:
                loadingView
            case .loaded:
                loadedView
            case .error:
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .refreshable {
            await viewModel.loadItemDetail(
                id: id, category: category, refresh: true)
        }
        .alert(
            "Error", isPresented: $viewModel.showError,
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadItemDetail(id: id, category: category)
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .environmentObject(viewModel)
        .enableInjection()
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Loaded View
    private var loadedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
                .overlay(alignment: .topTrailing) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding([.top, .trailing], 8)
                    }
                }

            actionsView
                .padding(.horizontal)
                .padding(.top)

            ItemViewDescription(item: viewModel.item)

            if let item = viewModel.item {
                Divider()
                    .padding(.vertical)

                ItemViewPosts(item: item)
            }
        }
    }

    // MARK: - Error View
    private var errorView: some View {
        EmptyStateView(
            String(localized: "item_error_title", table: "Item"),
            systemImage: "exclamationmark.triangle",
            description: Text(
                String(localized: "item_error_description", table: "Item")
            )
        )
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                coverImageView
                itemDetailsView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .padding(.top)
    }

    private var coverImageView: some View {
        ItemCoverView(
            item: viewModel.item,
            size: .large
        )
    }

    private var itemDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                ItemTitleView(
                    item: viewModel.item,
                    mode: .titleAndSubtitle,
                    size: .large
                )
            }
            .lineLimit(3)

            ItemRatingView(item: viewModel.item, size: .large)

            if !viewModel.metadata.isEmpty {
                ItemDescriptionView(
                    item: viewModel.item,
                    mode: .metadata,
                    size: .large,
                    action: {
                        HapticService.shared.selection()
                        router.presentSheet(.itemDetails(item: viewModel.item!))
                    }
                )
            }
        }
    }

    // MARK: - Actions View
    private var actionsView: some View {
        VStack(spacing: 12) {
            shelfTypeButtons

            if viewModel.isMarkLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let markDataController = viewModel.markDataController {
                ItemMarkView(markController: markDataController, size: .large)
            }
        }
        .onChange(of: viewModel.isRefreshing) { newValue in
            if newValue {
                viewModel.refresh()
            }
        }
    }

    private var shelfTypeButtons: some View {
        HStack(spacing: 8) {
            ForEach([ShelfType.wishlist, .progress, .complete], id: \.self) {
                type in
                if let item = viewModel.item {
                    Group {
                        if let mark = viewModel.markDataController?.mark,
                            mark.shelfType == type
                        {
                            Button {
                                router.presentSheet(
                                    .editShelfItem(
                                        mark: mark, shelfType: type,
                                        detentLevel: .detailed))
                                HapticFeedback.impact(.medium)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(
                                        symbol: type.symbolActionStateDoneFill)
                                    Text(
                                        type.displayNameForCategory(
                                            viewModel.item?.category)
                                    )
                                }
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(ShelfTypeButtonStyle(filled: false))
                        } else {
                            Button {
                                router.presentSheet(
                                    .addToShelf(
                                        item: item, shelfType: type,
                                        detentLevel: .detailed))
                                HapticFeedback.impact(.medium)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(symbol: type.symbolImage)
                                    Text(
                                        type.displayNameForCategory(
                                            viewModel.item?.category)
                                    )
                                }
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(ShelfTypeButtonStyle(filled: true))
                        }
                    }
                    .disabled(viewModel.isMarkLoading)
                }
            }
        }
    }

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                if let item = viewModel.item {
                    ItemOpenInView(
                        item: item, accountsManager: accountsManager
                    ).bodyMenu
                }
                if let url = viewModel.shareURL {
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

// MARK: - Button Style
private struct ShelfTypeButtonStyle: ButtonStyle {
    let filled: Bool

    init(filled: Bool = false) {
        self.filled = filled
    }

    private let cornerRadius: CGFloat = 8
    private let strokeWidth: CGFloat = 1
    private let color: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(filled ? color.opacity(0.2) : Color.clear)
            )
            .foregroundStyle(filled ? color : color)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        filled ? color.opacity(0.4) : color,
                        lineWidth: strokeWidth)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
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
