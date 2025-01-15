//
//  ItemDetailViewContainer.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct ItemDetailViewContainer: View {
    @StateObject private var viewModel = ItemDetailViewModel()
    
    let id: String
    let category: ItemCategory
    let item: (any ItemProtocol)?
    
    init(id: String, category: ItemCategory, item: (any ItemProtocol)? = nil) {
        self.id = id
        self.category = category
        self.item = item
    }
    
    var body: some View {
        ItemDetailView(
            viewModel: viewModel,
            id: id,
            category: category
        )
    }
}

#Preview {
    NavigationStack {
        ItemDetailViewContainer(
            id: "preview_id",
            category: .book
        )
        .environmentObject(Router())
        .environmentObject(AppAccountsManager())
    }
} 
