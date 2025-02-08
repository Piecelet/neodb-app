//
//  GalleryCategoryView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct GalleryCategoryView: View {
    let galleryState: GalleryState
    @EnvironmentObject private var router: Router
    
    var body: some View {
        List {
            if let items = galleryState.trendingGallery as? [ItemSchema] {
                ForEach(items, id: \.uuid) { item in
                    Button {
                        HapticFeedback.selection()
                        router.navigate(to: .itemDetailWithItem(item: item))
                    } label: {
                        SearchItemView(item: item, showCategory: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(galleryState.galleryCategory.displayName)
        .navigationBarTitleDisplayMode(.large)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    NavigationStack {
        GalleryCategoryView(
            galleryState: GalleryState(
                galleryCategory: .book,
                trendingGallery: [ItemSchema.preview]
            )
        )
        .environmentObject(Router())
    }
}

