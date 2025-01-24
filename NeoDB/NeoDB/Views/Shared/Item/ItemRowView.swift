//
//  ItemRowView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import Kingfisher

struct ItemRowView: View {
    let item: any ItemProtocol
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            ItemCoverView(item: item, size: .medium)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle ?? "")
                    .font(.headline)
                    .lineLimit(2)
                
                if let rating = item.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", rating))
                    }
                    .font(.subheadline)
                }
                
                Text(item.brief)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
