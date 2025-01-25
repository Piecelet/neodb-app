//
//  MarkView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct MarkView: View {
    @StateObject private var viewModel: MarkViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @State private var showAdvanced = false
    @State private var detent: PresentationDetent = .medium

    init(
        item: any ItemProtocol, mark: MarkSchema? = nil,
        shelfType: ShelfType? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: MarkViewModel(
                item: item, mark: mark, shelfType: shelfType))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text(viewModel.title)
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            .padding()

            List {
                // Shelf Type
                Section {
                    shelfTypeButtons
                }

                // Rating
                Section {
//                    RatingView(rating: $viewModel.rating)
                    StarRatingView(inputRating: $viewModel.rating)
                        .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)

                // Comment
                Section {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 100)
                } header: {
                    Text("mark_comment_label", tableName: "Item")
                } footer: {
                    Text("mark_comment_optional", tableName: "Item")
                }

                // Advanced Options
                Section {
                    DisclosureGroup(
                        String(
                            localized: "mark_advanced_section", table: "Item"),
                        isExpanded: $showAdvanced
                    ) {
                        Toggle(
                            String(
                                localized: "mark_public_toggle", table: "Item"),
                            isOn: $viewModel.isPublic)
                        Toggle(
                            String(
                                localized: "mark_share_fediverse_toggle",
                                table: "Item"),
                            isOn: $viewModel.postToFediverse)

                        Toggle(
                            String(
                                localized: "mark_use_current_time_toggle",
                                table: "Item"),
                            isOn: $viewModel.useCurrentTime)

                        if !viewModel.useCurrentTime {
                            DatePicker(
                                String(
                                    localized: "mark_created_time_label",
                                    table: "Item"),
                                selection: $viewModel.createdTime,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                    }
                }

                // Delete Button
                if viewModel.existingMark != nil {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteMark()
                            }
                        } label: {
                            Text("mark_delete_button", tableName: "Item")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .safeContentMargins(
                .top, EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            )
            .scrollContentBackground(.hidden)

            // Bottom Save Button
            VStack(spacing: 16) {
                Button {
                    Task {
                        await viewModel.saveMark()
                    }
                } label: {
                    Text("mark_save_button", tableName: "Item")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(.ultraThinMaterial)
        }
        .background(.ultraThinMaterial)
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .onChange(of: viewModel.isDismissed) { dismissed in
            if dismissed {
                dismiss()
            }
        }
        .alert(
            String(localized: "mark_error_title", table: "Item"),
            isPresented: $viewModel.showError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.accountsManager = accountsManager
        }
        .enableInjection()
    }

    private var shelfTypeButtons: some View {
        HStack(spacing: 12) {
            ForEach(ShelfType.allCases, id: \.self) { type in
                shelfTypeButton(for: type)
            }
        }
        .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
        .listRowBackground(Color.clear)
    }

    private func shelfTypeButton(for type: ShelfType) -> some View {
        Button {
            if viewModel.shelfType != type {
                viewModel.shelfType = type
                HapticFeedback.impact(.light)
            }
        } label: {
            VStack(spacing: 4) {
                Image(
                    symbol: (viewModel.shelfType == type)
                        ? type.symbolImageFill : type.symbolImage
                )
                .font(.system(size: 22))
                Text(type.displayName)
                    .font(.caption2)
            }
            .frame(width: 64)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(
                viewModel.shelfType == type
                    ? Color.accentColor : .secondary
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.primary, lineWidth: 1.5)
                    .background(.secondary.opacity(0.2))
                    .opacity(viewModel.shelfType == type ? 1 : 0)
            )
            .foregroundStyle(.accent)
        }
        .buttonStyle(.plain)
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}
