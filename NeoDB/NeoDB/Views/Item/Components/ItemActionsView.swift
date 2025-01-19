//
//  ItemActions.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct ItemActionsView: View {
    @StateObject private var viewModel: ItemActionsViewModel
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var itemViewModel: ItemViewModel

    let isRefreshing: Bool

    init(isRefreshing: Bool = false) {
        self.isRefreshing = isRefreshing
        self._viewModel = StateObject(wrappedValue: ItemActionsViewModel())
    }

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let mark = viewModel.mark {
                // Show existing mark info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let rating = mark.ratingGrade {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("\(rating)")
                                .foregroundStyle(.primary)
                            Text("/10")
                                .foregroundStyle(.secondary)
                        }
                        if mark.ratingGrade != nil {
                            Text("・")
                                .foregroundStyle(.secondary)
                        }
                        Text(mark.shelfType.displayName)
                            .foregroundStyle(.primary)
                        Text("・")
                            .foregroundStyle(.secondary)
                        Text(mark.createdTime.formatted)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    if let comment = mark.commentText, !comment.isEmpty {
                        Text(comment)
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Primary Action
            Button {
                if let item = itemViewModel.item {
                    if let mark = viewModel.mark {
                        router.presentedSheet = .editShelfItem(mark: mark)
                    } else {
                        router.presentedSheet = .addToShelf(item: item)
                    }
                }
            } label: {
                HStack {
                    Image(
                        systemName: viewModel.shelfType == nil
                            ? "plus" : "checkmark")
                    if let shelfType = viewModel.shelfType {
                        Text(shelfType.displayName)
                    } else {
                        Text("Add to Shelf")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            // Share Button and External Links have been moved to ItemView toolbar
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.accountsManager = accountsManager
            viewModel.itemViewModel = itemViewModel
        }
        .onChange(of: isRefreshing) { newValue in
            if newValue {
                viewModel.refresh()
            }
        }
    }
}

#Preview {
    ItemActionsView()
        .environmentObject(Router())
        .environmentObject(AppAccountsManager())
        .environmentObject(ItemViewModel())
        .padding()
}
