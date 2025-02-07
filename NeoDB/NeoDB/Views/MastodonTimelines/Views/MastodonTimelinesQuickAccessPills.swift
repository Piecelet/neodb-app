//
//  MastodonTimelinesQuickAccessPills.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/7/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

@MainActor
struct MastodonTimelinesQuickAccessPills: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager

    @Binding var pinnedFilters: [MastodonTimelinesFilter]
    @Binding var timeline: MastodonTimelinesFilter

    @State private var draggedFilter: MastodonTimelinesFilter?

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(pinnedFilters) { filter in
                    // makePill(filter)
                }
            }
        }
        // .scrollClipDisabled()
        .scrollIndicators(.never)
        // .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
//        .onChange(of: currentAccount.lists) { _, lists in
//            guard client.isAuth else { return }
//            var filters = pinnedFilters
//            for (index, filter) in filters.enumerated() {
//                switch filter {
//                case let .list(list):
//                    if let accountList = lists.first(where: { $0.id == list.id }
//                    ),
//                        accountList.title != list.title
//                    {
//                        filters[index] = .list(list: accountList)
//                    }
//                default:
//                    break
//                }
//            }
//            pinnedFilters = filters
//        }
    }

    // @ViewBuilder
    // private func makePill(_ filter: MastodonTimelinesFilter) -> some View {
    //     if !isFilterSupported(filter) {
    //         EmptyView()
    //     } else if filter == timeline {
    //         makeButton(filter)
    //             .buttonStyle(.borderedProminent)
    //     } else {
    //         makeButton(filter)
    //             .buttonStyle(.bordered)
    //     }
    // }

    // private func makeButton(_ filter: MastodonTimelinesFilter) -> some View {
    //     Button {
    //         timeline = filter
    //     } label: {
    //         switch filter {
    //         case .hashtag:
    //             Label(
    //                 filter.title.replacingOccurrences(of: "#", with: ""),
    //                 systemImage: filter.iconName())
    //         case let .list(list):
    //             if let list = currentAccount.lists.first(where: {
    //                 $0.id == list.id
    //             }) {
    //                 Label(list.title, systemImage: filter.iconName())
    //             }
    //         default:
    //             Label(filter.localizedTitle(), systemImage: filter.iconName())
    //         }
    //     }
    //     .transition(.push(from: .leading).combined(with: .opacity))
    //     .onDrag {
    //         draggedFilter = filter
    //         return NSItemProvider()
    //     }
    //     .onDrop(
    //         of: [.text],
    //         delegate: PillDropDelegate(
    //             destinationItem: filter,
    //             items: $pinnedFilters,
    //             draggedItem: $draggedFilter)
    //     )
    //     .buttonBorderShape(.capsule)
    //     .controlSize(.mini)

    // }

    private func isFilterSupported(_ filter: MastodonTimelinesFilter) -> Bool {
        switch filter {
        default:
            return true
        }
    }
}

struct PillDropDelegate: DropDelegate {
    let destinationItem: MastodonTimelinesFilter
    @Binding var items: [MastodonTimelinesFilter]
    @Binding var draggedItem: MastodonTimelinesFilter?

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info _: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info _: DropInfo) {
        if let draggedItem {
            let fromIndex = items.firstIndex(of: draggedItem)
            if let fromIndex {
                let toIndex = items.firstIndex(of: destinationItem)
                if let toIndex, fromIndex != toIndex {
                    withAnimation {
                        self.items.move(
                            fromOffsets: IndexSet(integer: fromIndex),
                            toOffset: toIndex > fromIndex
                                ? (toIndex + 1) : toIndex)
                    }
                }
            }
        }
    }
}
