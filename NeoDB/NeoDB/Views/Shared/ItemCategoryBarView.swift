//
//  MailTabBar.swift
//  NeoDB
//
//  Created by citron on 1/20/25.
//

import SwiftUI

enum ItemCategoryModel: String, CaseIterable {
    case book = "Books"
    case movie = "Movies"
    case tv = "TV Shows"
    case music = "Music"
    case allItems = "All"
    
    var color: Color {
        switch self {
        case .book: .blue
        case .movie: .green
        case .tv: .indigo
        case .music: .pink
        case .allItems: Color.primary
        }
    }
    
    var symbolImage: String {
        switch self {
        case .book: "book.fill"
        case .movie: "film.fill"
        case .tv: "tv.fill"
        case .music: "music.note"
        case .allItems: "square.grid.2x2.fill"
        }
    }
    
    var category: ItemCategory? {
        switch self {
        case .book: return .book
        case .movie: return .movie
        case .tv: return .tv
        case .music: return .music
        case .allItems: return nil
        }
    }
}

struct ItemCategoryBarView: View {
    @Binding var activeTab: ItemCategoryModel
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        GeometryReader {
            let size = $0.size
            let allItemsOffset = size.width - (40 * CGFloat(ItemCategoryModel.allCases.count - 1))
            
            HStack(spacing: 8) {
                HStack(spacing: activeTab == .allItems ? -15 : 8) {
                    ForEach(ItemCategoryModel.allCases.filter({ $0 != .allItems }), id: \.rawValue) { tab in
                        ResizableTabButton(tab)
                    }
                }
                
                if activeTab == .allItems {
                    ResizableTabButton(.allItems)
                        .transition(.offset(x: allItemsOffset))
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(height: 50)
    }
    
    @ViewBuilder
    func ResizableTabButton(_ tab: ItemCategoryModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: tab.symbolImage)
                .opacity(activeTab != tab ? 1 : 0)
                .overlay {
                    Image(systemName: tab.symbolImage)
                        .symbolVariant(.fill)
                        .opacity(activeTab == tab ? 1 : 0)
                }
            
            if activeTab == tab {
                Text(tab.rawValue)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(tab == .allItems ? schemeColor : activeTab == tab ? .white : .gray)
        .frame(maxHeight: .infinity)
        .frame(maxWidth: activeTab == tab ? .infinity : nil)
        .padding(.horizontal, activeTab == tab ? 10 : 20)
        .background {
            Rectangle()
                .fill(activeTab == tab ? tab.color : .inActiveTab)
        }
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.background)
                .padding(activeTab == .allItems && tab != .allItems ? -3 : 3)
        }
        .contentShape(.rect)
        .onTapGesture {
            guard tab != .allItems else { return }
            withAnimation(.bouncy) {
                if activeTab == tab {
                    activeTab = .allItems
                } else {
                    activeTab = tab
                }
            }
        }
    }
    
    var schemeColor: Color {
        scheme == .dark ? .black : .white
    }
}
