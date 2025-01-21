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

    init(item: ItemSchema) {
        _viewModel = StateObject(wrappedValue: StatusItemViewModel(item: item))
    }

    var body: some View {
        Button {
            router.navigate(to: .itemDetailWithItem(item: viewModel.item.toItemSchema))
        } label: {
            LazyVStack {
                HStack(spacing: 12) {
                    // Cover Image
                    KFImage(viewModel.item.coverImageUrl)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(2 / 3, contentMode: .fit)
                                .frame(height: 64)
                        }
                        .onFailure { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(2 / 3, contentMode: .fit)
                                .frame(height: 64)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay {
                            if viewModel.showSkeleton {
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        ProgressView()
                                    }
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.item.displayTitle ?? "")
                            .font(.headline)
                            .lineLimit(2)
                        
                        HStack(spacing: 4) {
                            if let rating = viewModel.item.rating {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                            Group {
                                if let movie = viewModel.item as? MovieSchema,
                                   let year = movie.year {
                                    Text(String(year))
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        .font(.caption)

                        Text(viewModel.item.brief)
                            .font(.caption2)
                            .foregroundStyle(secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.gray).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
