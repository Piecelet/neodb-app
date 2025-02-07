//
//  MailTabBar.swift
//  NeoDB
//
//  Created by citron on 1/20/25.
//

import SwiftUI

struct ItemCategoryBarView: View {
    @Binding var activeTab: ItemCategory.shelfAvailable
    @Environment(\.colorScheme) private var scheme
    @Namespace private var animation
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ResizableTabButton(.allItems)
                            .id(ItemCategory.shelfAvailable.allItems)

                        HStack(spacing: activeTab == .allItems ? -8 : 8) {
                            ForEach(
                                ItemCategory.shelfAvailable.allCases.filter({
                                    $0 != .allItems
                                }), id: \.self
                            ) { tab in
                                ResizableTabButton(tab)
                                    .id(tab)
                            }
                        }
                        .padding(.bottom, activeTab == .allItems ? 2.5 : 0)
                    }
                    .padding(.horizontal)
                    .frame(minWidth: geometry.size.width)
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }
        }
        .frame(height: 40)
        .animation(.bouncy, value: activeTab)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    @ViewBuilder
    func ResizableTabButton(_ tab: ItemCategory.shelfAvailable) -> some View {
        HStack(spacing: 6) {
            Image(symbol: tab.symbolImage)
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
                .opacity(activeTab != tab ? 1 : 0)
                .overlay {
                    Image(symbol: tab.symbolImageFill)
                        .font(.system(size: 16))
                        .frame(width: 20, height: 20)
                        .opacity(activeTab == tab ? 1 : 0)
                }

            if activeTab == tab || tab == .allItems {
                Text(tab.displayName)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(
            /*tab == .allItems ? schemeColor : */activeTab == tab
                ? .white : .gray
        )
        .frame(maxHeight: .infinity)
        .frame(maxWidth: activeTab == tab ? .infinity : nil)
        .padding(
            .horizontal,
            activeTab == tab
                ? 14
                : (tab == .allItems ? 16 : activeTab == .allItems ? 14 : 20)
        )
        .background {
            Rectangle()
                .fill(activeTab == tab ? AnyShapeStyle(tab.color) : AnyShapeStyle(Color.gray.opacity(0.15)))
                .background {
                    Rectangle()
                        .fill(activeTab == tab ? AnyShapeStyle(tab.color) : AnyShapeStyle(.background))
                }
        }
        .clipShape(.rect(cornerRadius: 14, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background.opacity(0.75))
                .padding(activeTab == .allItems && tab != .allItems ? -3 : 3)
        }
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.bouncy) {
                if activeTab == tab {
                    if tab != .allItems {
                        activeTab = .allItems
                        scrollProxy?.scrollTo(
                            ItemCategory.shelfAvailable.allItems,
                            anchor: .leading)
                    }
                } else {
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
