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

    init(item: any ItemProtocol, mode: Mode = .card) {
        _viewModel = StateObject(wrappedValue: StatusItemViewModel(item: item))
        self.mode = mode
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
                                hideRatingCount: true,
                                showCategory: true)
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
            .padding(.horizontal, mode == .card ? 12 : 20)
            .padding(.vertical, 12)
            .background(Color.grayBackground)
            .clipShape(RoundedRectangle(cornerRadius: mode == .card ? 8 : 0))
        }
        .buttonStyle(.plain)
        .alert("Error", isPresented: .constant(false)) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
        }
//        .onDisappear {
//            viewModel.cleanup()
//        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
