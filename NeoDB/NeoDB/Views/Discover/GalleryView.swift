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
            .refreshable {
                // Refresh all categories
                for category in ItemCategory.galleryCategory.allCases {
                    await viewModel.loadGallery(
                        category: category, refresh: true)
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

                        if state.isLoading {
                            galleryView(ItemSchema.placeholders, isPlaceholder: true)
                        } else if let gallery = state.gallery {
                            galleryView(gallery)
                        }

                        // if let state = viewModel.galleryStates[category],
                        //    let gallery = state.gallery {
                        //     Section {
                        //         galleryView(gallery)
                        //     }
                        //     .listRowSeparator(.hidden)
                        // } else if let state = viewModel.galleryStates[category],
                        //           state.isLoading {
                        //     Section {
                        //         ProgressView()
                        //             .frame(maxWidth: .infinity)
                        //             .listRowSeparator(.hidden)
                        //     }
                        // }
                    }
                    .listRowSeparator(.hidden)
                    .padding(.top, 20)
                    .listRowInsets(EdgeInsets())
                }
            }
        }
    }

    private func galleryView(
        _ items: TrendingItemResult, isPlaceholder: Bool = false
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items, id: \.uuid) { item in
                    Button {
                        HapticFeedback.selection()
                        router.navigate(to: .itemDetailWithItem(item: item))
                    } label: {
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
                    .disabled(isPlaceholder)
                    .redacted(reason: isPlaceholder ? .placeholder : [])
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
