//
//  StatusItemView.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import Kingfisher
import SwiftUI

struct StatusItemView: View {
    @StateObject private var viewModel: StatusItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager

    init(item: any ItemProtocol) {
        _viewModel = StateObject(wrappedValue: StatusItemViewModel(item: item))
    }

    var body: some View {
        Button {
            router.navigate(
                to: .itemDetailWithItem(item: viewModel.item.toItemSchema))
        } label: {
            LazyVStack {
                HStack(spacing: 12) {
                    // Cover Image
                    ItemCoverView(
                        item: viewModel.item,
                        size: .small,
                        showSkeleton: viewModel.showSkeleton
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        ItemTitleView(
                            item: viewModel.item,
                            mode: .title,
                            size: .medium
                        )

                        HStack(spacing: 4) {
                            ItemRatingView(
                                item: viewModel.item, size: .small,
                                hideRatingCount: true)
                            Text("/")
                                .foregroundStyle(.secondary)
                            Text(viewModel.item.category.displayName)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)

                        ItemDescriptionView(
                            item: viewModel.item,
                            mode: .metadata,
                            size: .small
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        router.presentSheet(.addToShelf(item: viewModel.item.toItemSchema))
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
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.gray).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
