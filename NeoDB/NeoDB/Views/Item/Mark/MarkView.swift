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

    init(item: any ItemProtocol, mark: MarkSchema? = nil) {
        _viewModel = StateObject(
            wrappedValue: MarkViewModel(item: item, mark: mark))
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

            ScrollView {
                // Shelf Type
                Section {
                    HStack(spacing: 16) {
                        ForEach(ShelfType.allCases, id: \.self) { type in
                            Button {
                                viewModel.shelfType = type
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: type.iconName)
                                        .font(.title2)
                                    Text(type.displayName)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(
                                    viewModel.shelfType == type
                                        ? .primary : .secondary)
                            }
                            .buttonStyle(.borderless)

                        }
                    }
                    .padding(.vertical, 8)
                }

                // Rating
                VStack(alignment: .leading, spacing: 12) {

                    RatingView(rating: $viewModel.rating)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

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
                    DisclosureGroup(String(localized: "mark_advanced_section", table: "Item"), isExpanded: $showAdvanced) {
                        Toggle(String(localized: "mark_public_toggle", table: "Item"), isOn: $viewModel.isPublic)
                        Toggle(
                            String(localized: "mark_share_fediverse_toggle", table: "Item"),
                            isOn: $viewModel.postToFediverse)

                        Toggle(
                            String(localized: "mark_use_current_time_toggle", table: "Item"),
                            isOn: $viewModel.useCurrentTime)

                        if !viewModel.useCurrentTime {
                            DatePicker(
                                String(localized: "mark_created_time_label", table: "Item"),
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
                        .padding(.vertical, 12)
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
        .alert(String(localized: "mark_error_title", table: "Item"), isPresented: $viewModel.showError) {
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

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}
