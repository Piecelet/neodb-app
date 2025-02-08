//
//  GalleryView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Kingfisher
import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager

    private let coverSize: ItemCoverSize = .large
    private var coverWidth: CGFloat {
        coverSize.height * AppConfig.defaultItemCoverRatio
    }

    var body: some View {
        galleryContent
            .task {
                viewModel.accountsManager = accountsManager
                // Load all categories
                for category in ItemCategory.galleryCategory.allCases {
                    await viewModel.loadGallery(category: category)
                }
            }
            .enableInjection()
    }

    private var galleryContent: some View {
        ForEach(ItemCategory.galleryCategory.availableCategories, id: \.self) {
            category in
            if let state = viewModel.galleryStates[category] {
                Section {
                    VStack(alignment: .leading) {
                        Button {
                            router.navigate(
                                to: .galleryCategory(
                                    galleryState: viewModel.galleryStates[
                                        category]!))
                        } label: {
                            HStack(alignment: .center, spacing: 4) {
                                Text(category.displayName)
                                    .font(.system(size: 20))
                                    .foregroundStyle(.primary)
                                Image(systemSymbol: .chevronRight)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        .buttonStyle(.plain)

                        if state.trendingGallery.isEmpty == false {
                            if state.isLoading || !state.isInited || state.isRefreshing {
                                galleryView(isPlaceholder: true)
                            } else {
                                galleryView(isPlaceholder: true)
                            }
                        } else {
                            galleryView(state.trendingGallery)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .padding(.top, 20)
                    .listRowInsets(EdgeInsets())
                }
            }
        }
    }

    private func galleryView(
        _ items: TrendingItemResult
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items, id: \.uuid) { item in
                    Button {
                        HapticFeedback.selection()
                        router.navigate(to: .itemDetailWithItem(item: item))
                    } label: {
                        galleryItemView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func galleryView(isPlaceholder: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(ItemSchema.placeholders, id: \.uuid) { item in
                    galleryItemView(item: item)
                    .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal)
        }
    }

    private func galleryItemView(item: ItemSchema) -> some View {
                        VStack(alignment: .leading, spacing: 8) {
                            ItemCoverView(
                                item: item, size: coverSize, alignment: .fixed)

                            ItemTitleView(
                                item: item, mode: .title, size: .compact,
                                alignment: .center
                            )
                            .frame(width: coverWidth)
                        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
