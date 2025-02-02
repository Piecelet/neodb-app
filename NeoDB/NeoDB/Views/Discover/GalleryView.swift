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
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        ForEach(viewModel.galleryItems) { gallery in
            Section {
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
                    .buttonStyle(.plain)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(gallery.items, id: \.uuid) { item in
                                Button {
                                    HapticFeedback.selection()
                                    router.navigate(to: .itemDetailWithItem(item: item))
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ItemCoverView(item: item, size: .large, alignment: .fixed)

                                        ItemTitleView(item: item, mode: .title, size: .compact, alignment: .center)
                                            .frame(width: ItemCoverSize.large.height * AppConfig.defaultItemCoverRatio)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    List {
        GalleryView(viewModel: SearchViewModel())
            .environmentObject(Router())
    }
}
