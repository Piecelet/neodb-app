//
//  StatusItemView.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import SwiftUI
import Kingfisher

struct StatusItemView: View {
    @StateObject private var viewModel: StatusItemViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    init(item: ItemSchema) {
        _viewModel = StateObject(wrappedValue: StatusItemViewModel(item: item))
    }
    
    var body: some View {
        Button {
            router.navigate(to: .itemDetailWithItem(item: viewModel.item))
        } label: {
            HStack(spacing: 12) {
                // Cover Image
                KFImage(viewModel.item.coverImageUrl)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 60)
                    }
                    .onFailure { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 60)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThinMaterial)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.item.displayTitle ?? "")
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let rating = viewModel.item.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", rating))
                        }
                        .font(.subheadline)
                    }
                    
                    Text(viewModel.item.brief ?? viewModel.item.type)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
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
    }
} 
