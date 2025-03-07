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
    
    // 添加状态追踪
    @State private var isLoading = false
    @State private var hasLoaded = false

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
            // 只在未加载过且未在加载中时进行加载
            guard !hasLoaded && !isLoading else { return }
            
            isLoading = true
            defer { isLoading = false }
            
            // 使用 Task 在后台线程加载数据
            if let fetched = await Task.detached(priority: .userInitiated) { () -> (any ItemProtocol)? in
                await itemRepository.fetchItem(
                    for: viewModel.item,
                    refresh: false,
                    accountsManager: accountsManager
                )
            }.value {
                // 在主线程更新 UI
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.item = fetched
                        hasLoaded = true
                    }
                }
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
