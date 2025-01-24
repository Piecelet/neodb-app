//
//  ItemRowView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct SearchItemView: View {
    let item: any ItemProtocol
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            ItemCoverView(item: item, size: .medium)
            
            VStack(alignment: .leading, spacing: 4) {
                ItemTitleView(item: item, mode: .title, size: .medium)

                ItemRatingView(item: item, size: .medium, showCategory: true)
                
                ItemDescriptionView(item: item, mode:.brief , size: .medium)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
} 
