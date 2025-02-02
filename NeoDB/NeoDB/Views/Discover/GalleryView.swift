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
    let galleryItems: [GalleryResult]
    @EnvironmentObject private var router: Router
    
    private let coverSize: ItemCoverSize = .large
    private var coverWidth: CGFloat {
        coverSize.height * AppConfig.defaultItemCoverRatio
    }

    var body: some View {
        ForEach(galleryItems) { gallery in
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
                .listRowInsets(.horizontal(0))
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
        GalleryView(galleryItems: [
            GalleryResult(
                name: "Preview Gallery",
                items: [ItemSchema.preview]
            )
        ])
        .environmentObject(Router())
    }
}
