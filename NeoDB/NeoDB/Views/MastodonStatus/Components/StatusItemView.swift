//
//  StatusItemView.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import Kingfisher
import SwiftUI

struct StatusItemView: View {
    enum Mode {
        case card
        case indicator
    }

    let mode: Mode
    @StateObject private var viewModel: StatusItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var itemRepository: ItemRepository

    init(item: any ItemProtocol, mode: Mode = .card) {
        _viewModel = StateObject(wrappedValue: StatusItemViewModel(item: item))
        self.mode = mode
    }

    var body: some View {
        Button {
            router.navigate(
                to: .itemDetailWithItem(item: viewModel.item.toItemSchema)
            )
            TelemetryService.shared.trackItemViewFromStatus()
        } label: {
            VStack {
                HStack(spacing: 12) {
                    // Cover Image
                    ItemCoverView(
                        item: viewModel.item,
                        size: .small
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        ItemTitleView(
                            item: viewModel.item,
                            mode: .title,
                            size: .medium
                        )

                        ItemRatingView(
                            item: viewModel.item, size: .small,
                            hideRatingCount: true,
                            showCategory: true
                        )

                        ItemDescriptionView(
                            item: viewModel.item,
                            mode: .metadata,
                            size: .small
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        router.presentSheet(
                            .addToShelf(item: viewModel.item.toItemSchema))
                        TelemetryService.shared.trackMastodonStatusItemMark()
                        HapticFeedback.impact(.medium)
                    } label: {
                        Image(systemSymbol: .plusSquareDashed)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50, idealHeight: 64, maxHeight: 80)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, mode == .card ? 12 : 20)
            .padding(.vertical, 12)
            .background(Color.grayBackground)
            .clipShape(RoundedRectangle(cornerRadius: mode == .card ? 8 : 0))
        }
        .buttonStyle(.plain)
        .task {
            Task {
                // 使用全局 ItemRepository 加载数据
                if let fetched = await itemRepository.fetchItem(
                    for: viewModel.item,
                    refresh: false,
                    accountsManager: accountsManager
                ) {
                    // 当仓库成功加载到完整数据后，将数据更新到 ViewModel 中，
                    // 这样 StatusItemView 会直接显示最新的 item 内容。
                    viewModel.item = fetched
                }
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
