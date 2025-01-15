//
//  ItemActionsView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI

struct ItemActionsView: View {
    let item: any ItemProtocol
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.openURL) private var openURL
    
    private var shareURL: URL? {
        if let url = URL(string: item.url), url.host == nil {
            return URL(string: "https://\(accountsManager.currentAccount.instance)\(item.url)")
        }
        return URL(string: item.url)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Primary Action
            Button {
                router.presentedSheet = .addToShelf(item: item)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add to Shelf")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            
            HStack(spacing: 12) {
                // Share Button
                if let url = shareURL {
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
                if let resources = item.externalResources, !resources.isEmpty {
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
        .padding()
    }
}

//#Preview {
//    ItemActionsView(item: ItemSchema(
//        title: "Sample Item",
//        description: "A sample item description",
//        localizedTitle: [],
//        localizedDescription: [],
//        coverImageUrl: "https://example.com/image.jpg",
//        rating: 4.5,
//        ratingCount: 1234,
//        id: "1",
//        type: "book",
//        uuid: "1",
//        url: "/book/1",  // Testing relative URL
//        apiUrl: "https://api.example.com/item/1",
//        category: .book,
//        parentUuid: nil,
//        displayTitle: "Sample Item",
//        externalResources: [
//            ExternalResourceSchema(url: "https://example.com/external/1")
//        ],
//        brief: "A sample item brief description"
//    ))
//    .environmentObject(Router())
//    .environmentObject(AuthService())
//} 
