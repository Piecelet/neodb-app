//
//  TopTabBarView.swift
//  NeoDB
//
//  Created by citron on 1/22/25.
//

import SwiftUI

struct TopTabBarView<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let titleForItem: (T) -> String

    init(
        items: [T],
        selection: Binding<T>,
        titleForItem: @escaping (T) -> String
    ) {
        self.items = items
        self._selection = selection
        self.titleForItem = titleForItem
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(items, id: \.self) { item in
                    VStack(spacing: 8) {
                        Text(titleForItem(item))
                            .font(
                                .system(
                                    size: 15,
                                    weight: selection == item
                                        ? .semibold : .regular)
                            )
                            .foregroundStyle(
                                selection == item
                                    ? .primary : .secondary)

                        Rectangle()
                            .fill(
                                selection == item
                                    ? Color.accentColor : .clear
                            )
                            .frame(height: 2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            selection = item
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    struct PreviewWrapper: View {
        enum Tab: String, CaseIterable {
            case first = "First"
            case second = "Second"
            case third = "Third"
        }

        @State private var selection: Tab = .first

        var body: some View {
            TopTabBarView(
                items: Tab.allCases,
                selection: $selection
            ) { $0.rawValue }
            .enableInjection()
        }

        #if DEBUG
        @ObserveInjection var forceRedraw
        #endif
    }

    return PreviewWrapper()
}
