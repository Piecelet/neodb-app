//
//  MarkView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import SwiftUIIntrospect
import Parchment

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
            VStack(alignment: .leading, spacing: 0) {
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
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom)
                .padding(.leading, 4)
                shelfTypeButtons
            }
            .padding(.bottom)

            PageView(
                ShelfType.allCases,
                id: \.self,
                selectedIndex:
                    Binding(
                        get: { ShelfType.allCases.firstIndex(of: viewModel.shelfType ?? .wishlist) ?? 0 },
                        set: { index in
                            let type = ShelfType.allCases[index]
                            if viewModel.shelfType != type {
                                withAnimation {
                                    viewModel.shelfType = type
                                    HapticFeedback.impact(.light)
                                }
                            }
                        }
                    )
            ) { type in
                Page(type.displayName) {
                    if type == .wishlist {
                        markContentView
                    } else {
                        markContentViewWithRating
                    }
                }
            }
            .menuPosition(.top)
            .menuItemSpacing(20)
            .menuBackgroundColor(.clear)
            .menuHorizontalAlignment(.left)
            .indicatorColor(.accentColor)
            .indicatorOptions(.visible(height: 2, zIndex: 0, spacing: .zero, insets: .init(top: 0, left: 0, bottom: 0, right: 0)))
        }
        .background(.ultraThinMaterial)
        .compositingGroup()
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
        TopTabBarView(
            items: ShelfType.allCases,
            selection: Binding(
                get: { viewModel.shelfType },
                set: { newValue in
                    if viewModel.shelfType != newValue {
                        viewModel.shelfType = newValue
                        HapticFeedback.impact(.light)
                    }
                }
            )
        ) { $0.displayName }
    }

    private var markContentView: some View {
        markContentViewBase {
            EmptyView()
        }
    }

    private var markContentViewWithRating: some View {
        markContentViewBase {
            StarRatingView(inputRating: $viewModel.rating)
                .frame(maxWidth: .infinity)
        }
    }

    private func markContentViewBase<Content: View>(
        @ViewBuilder header: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            VStack {
                header()

                TextEditor(text: $viewModel.comment)
                    .frame(
                        minHeight: 100,
                        maxHeight: 300
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .overlay {
                        if viewModel.comment.isEmpty {
                            TextEditor(text: .constant("Write a comment..."))
                                .foregroundColor(.secondary)
                                .disabled(true)
                        }
                    }
                    .scrollDisabled(viewModel.comment.isEmpty)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.horizontal)

                advancedOptionsSection

                Spacer()

                if viewModel.existingMark != nil {
                    deleteButton
                }
            }
            .padding(.top, viewModel.shelfType == .wishlist ? 16 : 0)
            .scrollContentBackground(.hidden)

            saveButton
        }
    }

    private var advancedOptionsSection: some View {
        Section {
            DisclosureGroup(
                String(localized: "mark_advanced_section", table: "Item"),
                isExpanded: $showAdvanced
            ) {
                Toggle(
                    String(localized: "mark_public_toggle", table: "Item"),
                    isOn: $viewModel.isPublic)
                Toggle(
                    String(
                        localized: "mark_share_fediverse_toggle", table: "Item"),
                    isOn: $viewModel.postToFediverse)
                Toggle(
                    String(
                        localized: "mark_use_current_time_toggle", table: "Item"
                    ),
                    isOn: $viewModel.useCurrentTime)

                if !viewModel.useCurrentTime {
                    DatePicker(
                        String(
                            localized: "mark_created_time_label", table: "Item"),
                        selection: $viewModel.createdTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        }
    }

    private var deleteButton: some View {
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

    private var saveButton: some View {
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
        .compositingGroup()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}
