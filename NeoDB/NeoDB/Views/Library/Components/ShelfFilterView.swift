//
//  ShelfFilterView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI

struct ShelfFilterView: View {
    @Binding var selectedShelfType: ShelfType
    @Binding var selectedCategory: ItemCategory?
    let onShelfTypeChange: (ShelfType) -> Void
    let onCategoryChange: (ItemCategory?) -> Void
    
    @State private var activeTab: ItemCategory.shelfAvailable = .allItems
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Shelf Type Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShelfType.allCases, id: \.self) { type in
                        Button {
                            selectedShelfType = type
                            onShelfTypeChange(type)
                        } label: {
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedShelfType == type ?
                                Color.accentColor :
                                Color.secondary.opacity(0.1)
                            )
                            .foregroundStyle(
                                selectedShelfType == type ?
                                Color.white :
                                Color.primary
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Category Filter using ItemCategoryBarView
            ItemCategoryBarView(activeTab: $activeTab)
                .onChange(of: activeTab) { newValue in
                    selectedCategory = newValue.itemCategory
                    onCategoryChange(newValue.itemCategory)
                }
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
} 
