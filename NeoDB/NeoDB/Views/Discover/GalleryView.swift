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
                    await viewModel.loadGallery(category: category, refresh: true)
                }
            }
            .enableInjection()
    }

    private var galleryContent: some View {
        ForEach(ItemCategory.galleryCategory.allCases, id: \.self) { category in
            if let state = viewModel.galleryStates[category],
               let gallery = state.gallery {
                Section {
                    galleryView(gallery)
                }
                .listRowSeparator(.hidden)
            } else if let state = viewModel.galleryStates[category],
                      state.isLoading {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }
            }
        }
    }

    private func galleryView(_ gallery: GalleryResult) -> some View {
        VStack(alignment: .leading) {
            Button {
                router.navigate(to: .galleryCategory(gallery: gallery))
            } label: {
                HStack(alignment: .center, spacing: 4) {
                    Text(gallery.displayTitle)
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(gallery.items, id: \.uuid) { item in
                        Button {
                            HapticFeedback.selection()
                            router.navigate(to: .itemDetailWithItem(item: item))
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                ItemCoverView(item: item, size: coverSize, alignment: .fixed)

                                ItemTitleView(item: item, mode: .title, size: .compact, alignment: .center)
                                    .frame(width: coverWidth)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 20)
        .listRowInsets(EdgeInsets())
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
