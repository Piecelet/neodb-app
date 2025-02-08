//
//  GalleryCategoryView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct GalleryCategoryView: View {
    let trendingGallery: TrendingGalleryResult
    @EnvironmentObject private var router: Router
    
    var body: some View {
        List {
            ForEach(trendingGallery.items, id: \.uuid) { item in
                Button {
                    HapticFeedback.selection()
                    router.navigate(to: .itemDetailWithItem(item: item))
                } label: {
                    SearchItemView(item: item, showCategory: false)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .navigationTitle(gallery.displayTitle)
        .navigationBarTitleDisplayMode(.large)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    NavigationStack {
        GalleryCategoryView(gallery: GalleryResult(
            name: "Preview Gallery",
            items: [ItemSchema.preview]
        ))
        .environmentObject(Router())
    }
}

