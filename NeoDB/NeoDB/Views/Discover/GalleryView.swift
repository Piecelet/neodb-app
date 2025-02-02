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
                    HStack(alignment: .bottom) {
                        Text(gallery.displayTitle)
                            .font(.headline)
                        Image(systemSymbol: .chevronRight)
                            .foregroundStyle(.secondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(gallery.items, id: \.uuid) { item in
                                Button {
                                    HapticFeedback.selection()
                                    router.navigate(
                                        to: .itemDetailWithItem(item: item))
                                } label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ItemCoverView(item: item, size: .large, alignment: .vertical)

                                        Text(item.displayTitle ?? "")
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .frame(width: 100)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .listRowInsets(EdgeInsets())
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
