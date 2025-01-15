//
//  ItemActions.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct ItemActionsView: View {
    @StateObject private var viewModel: ItemActionsViewModel
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    init(item: (any ItemProtocol)?, onAddToShelf: @escaping () -> Void) {
        let model = ItemActionsViewModel(item: item)
        model.onAddToShelf = onAddToShelf
        _viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let mark = viewModel.mark {
                // Show existing mark info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let rating = mark.ratingGrade {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("\(rating)")
                                .foregroundStyle(.primary)
                            Text("/10")
                                .foregroundStyle(.secondary)
                        }
                        if mark.ratingGrade != nil {
                            Text("・")
                                .foregroundStyle(.secondary)
                        }
                        Text(mark.createdTime.formatted)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    
                    if let comment = mark.commentText, !comment.isEmpty {
                        Text(comment)
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Primary Action
            Button(action: viewModel.onAddToShelf) {
                HStack {
                    Image(systemName: viewModel.shelfType == nil ? "plus" : "checkmark")
                    if let shelfType = viewModel.shelfType {
                        Text(shelfType.displayName)
                    } else {
                        Text("Add to Shelf")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            
            HStack(spacing: 12) {
                // Share Button
                if let url = viewModel.shareURL {
                    ShareLink(item: url) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                
                // External Links
                if let resources = viewModel.item?.externalResources, !resources.isEmpty {
                    Menu {
                        ForEach(resources, id: \.url) { resource in
                            Button {
                                openURL(resource.url)
                            } label: {
                                Label(resource.url.host ?? "External Link", systemImage: "link")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Links")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.accountsManager = accountsManager
        }
    }
}

#Preview {
    ItemActionsView(
        item: ItemSchema.preview,
        onAddToShelf: {}
    )
    .environmentObject(AppAccountsManager())
    .padding()
}

private extension ItemSchema {
    static var preview: ItemSchema {
        ItemSchema(
            id: "1",
            type: "book",
            uuid: "1",
            url: "/book/1",  // Testing relative URL
            apiUrl: "https://api.example.com/item/1",
            category: .book,
            parentUuid: nil,
            displayTitle: "Sample Item",
            externalResources: [
                ExternalResourceSchema(url: URL(string: "https://example.com/external/1")!)
            ],
            title: "Sample Item",
            description: "A sample item description",
            localizedTitle: [],
            localizedDescription: [],
            coverImageUrl: nil,
            rating: 4.5,
            ratingCount: 1234,
            brief: "A sample item brief description"
        )
    }
} 
