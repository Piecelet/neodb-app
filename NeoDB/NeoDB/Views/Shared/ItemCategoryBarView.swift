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
    case game = "Games"
    case podcast = "Podcasts"
    case performance = "Performance"
    case allItems = "All"
    
    var color: Color {
        switch self {
        case .book: .blue
        case .movie: .green
        case .tv: .indigo
        case .music: .pink
        case .game: .orange
        case .podcast: .purple
        case .performance: .red
        case .allItems: Color.primary
        }
    }
    
    var symbolImage: String {
        switch self {
        case .book: "book.fill"
        case .movie: "film.fill"
        case .tv: "tv.fill"
        case .music: "music.note"
        case .game: "gamecontroller.fill"
        case .podcast: "mic.fill"
        case .performance: "theatermasks.fill"
        case .allItems: "square.grid.2x2.fill"
        }
    }
    
    var category: ItemCategory? {
        switch self {
        case .book: return .book
        case .movie: return .movie
        case .tv: return .tv
        case .music: return .music
        case .game: return .game
        case .podcast: return .podcast
        case .performance: return .performance
        case .allItems: return nil
        }
    }
}

struct ItemCategoryBarView: View {
    @Binding var activeTab: ItemCategoryModel
    @Environment(\.colorScheme) private var scheme
    @Namespace private var animation
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        HStack(spacing: activeTab == .allItems ? -15 : 8) {
                            ForEach(ItemCategoryModel.allCases.filter({ $0 != .allItems }), id: \.rawValue) { tab in
                                ResizableTabButton(tab)
                                    .id(tab)
                            }
                        }
                        
                        if activeTab == .allItems {
                            ResizableTabButton(.allItems)
                                .id(ItemCategoryModel.allItems)
                                .matchedGeometryEffect(id: "allItems", in: animation)
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(minWidth: geometry.size.width)
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }
        }
        .frame(height: 50)
        .animation(.bouncy, value: activeTab)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
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
            if activeTab == tab {
                withAnimation(.bouncy) {
                    activeTab = .allItems
                    scrollProxy?.scrollTo(ItemCategoryModel.allItems, anchor: .trailing)
                }
            } else {
                withAnimation(.bouncy) {
                    activeTab = tab
                    scrollProxy?.scrollTo(tab, anchor: .center)
                }
            }
        }
    }
    
    var schemeColor: Color {
        scheme == .dark ? .black : .white
    }
}
