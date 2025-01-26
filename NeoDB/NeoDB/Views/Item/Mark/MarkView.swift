//
//  MarkView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI
import SwiftUIIntrospect

struct MarkView: View {
    enum DetailLevel: Hashable {
        case brief
        case detailed
        
        var presentationDetent: PresentationDetent {
            switch self {
            case .brief: return .fraction(0.65)
            case .detailed: return .large
            }
        }
    }
    
    @StateObject private var viewModel: MarkViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @State private var detentLevel: DetailLevel

    init(
        item: any ItemProtocol,
        mark: MarkSchema? = nil,
        shelfType: ShelfType? = nil,
        detentLevel: DetailLevel = .brief
    ) {
        _viewModel = StateObject(
            wrappedValue: MarkViewModel(
                item: item, mark: mark, shelfType: shelfType))
        _detentLevel = State(initialValue: detentLevel)
    }

    var body: some View {
        NavigationStack {
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

                TabView(
                    selection: Binding(
                        get: { viewModel.shelfType },
                        set: { viewModel.shelfType = $0 }
                    )
                ) {
                    ForEach(ShelfType.allCases, id: \.self) { type in
                        if type == .wishlist {
                            markContentView
                                .tag(type)
                        } else {
                            markContentViewWithRating
                                .tag(type)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if viewModel.existingMark != nil {
                    deleteButton
                } else {
                    deleteButton
                        .hidden()
                }

                VStack(alignment: .center, spacing: 0) {
                    NavigationLink {
                        advancedSettingsView
                    } label: {
                        advancedOptionsLabel
                    }
                    saveButton
                }
                .background(.ultraThinMaterial)
                .compositingGroup()
            }
            .background(.ultraThinMaterial)
            .compositingGroup()
        }
        .navigationTitle(viewModel.title)
        .background(.ultraThinMaterial)
        .compositingGroup()
        .presentationDetents(
            [DetailLevel.brief.presentationDetent, DetailLevel.detailed.presentationDetent],
            selection: Binding(
                get: { self.detentLevel.presentationDetent },
                set: { detent in
                    self.detentLevel = detent == .large ? .detailed : .brief
                }
            )
        )
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
        .task {
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
        markContentViewBase(paddingTop: true) {
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
        paddingTop: Bool = false,
        @ViewBuilder header: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            VStack {
                header()

                TextEditor(text: $viewModel.comment)
                    .frame(
                        minHeight: detentLevel == .detailed
                            ? 200 : paddingTop ? 100 : 50,
                        maxHeight: 300
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .overlay {
                        if viewModel.comment.isEmpty {
                            TextEditor(
                                text: .constant(
                                    String(
                                        localized: "mark_comment_placeholder",
                                        table: "Item",
                                        comment:
                                            "Mark - Placeholder text shown in empty comment field"
                                    ))
                            )
                            .foregroundColor(.secondary)
                            .disabled(true)
                        }
                    }
                    .scrollDisabled(viewModel.comment.isEmpty)
                    .padding(10)
                    .background(.secondary.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top)
                    .onTapGesture {
                        withAnimation {
                            detentLevel = .detailed
                        }
                    }

                Spacer()
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var advancedOptionsLabel: some View {
        HStack {
            Label {
                Text(viewModel.visibility.displayText)
            } icon: {
                Image(symbol: viewModel.visibility.symbolImage)
                    .padding(.trailing, -6)
            }
            .labelStyle(.titleAndIcon)

            if viewModel.postToFediverse {
                Label {
                    Text(
                        "mark_share_fediverse_enabled_label",
                        tableName: "Item",
                        comment:
                            "Mark - Label shown in advanced options when post to fediverse is enabled"
                    )
                } icon: {
                    Image(systemSymbol: .arrow2Squarepath)
                        .padding(.trailing, -6)
                }
                .labelStyle(.titleAndIcon)
            } else {
                Label {
                    Text(
                        "mark_share_fediverse_disabled_label",
                        tableName: "Item",
                        comment:
                            "Mark - Label shown in advanced options when post to fediverse is disabled"
                    )
                } icon: {
                    Image(symbol: .custom("custom.arrow.2.squarepath.slash"))
                        .padding(.trailing, -6)
                }
                .labelStyle(.titleAndIcon)
            }

            if viewModel.changeTime {
                Label {
                    Text(
                        viewModel.createdTime.formatted(
                            date: .abbreviated, time: .omitted))
                } icon: {
                    Image(systemSymbol: .clock)
                        .padding(.trailing, -6)
                }
                .labelStyle(.titleAndIcon)
            }
            
            Image(systemSymbol: .chevronRight)
        }
        .padding(.horizontal, 18)
        .padding(.top)
        .font(.subheadline)
    }

    private var deleteButton: some View {
        Menu {
            Button(role: .destructive) {
                Task {
                    await viewModel.deleteMark()
                }
            } label: {
                Label(
                    String(
                        localized: "mark_delete_confirm_button", table: "Item",
                        comment: "Mark - Button to confirm deletion"),
                    systemSymbol: .trash
                )
                .labelStyle(.titleAndIcon)
            }
        } label: {
            Label(
                String(
                    localized: "mark_delete_button", table: "Item",
                    comment: "Mark - Button to delete mark"),
                systemSymbol: .trash
            )
            .frame(maxWidth: .infinity)
            .labelStyle(.titleAndIcon)
        }
        .font(.subheadline)
        .foregroundStyle(.gray)
        .disabled(viewModel.isLoading)
        .padding(.bottom)
    }

    private var saveButton: some View {
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
        .padding(.vertical)
    }

    private var advancedSettingsView: some View {
        Form {
            Section {
                Picker(
                    String(
                        localized: "mark_visibility_picker_label",
                        table: "Item",
                        comment: "Mark - Label for visibility picker"),
                    selection: $viewModel.visibility
                ) {
                    ForEach(MarkVisibility.allCases, id: \.self) { visibility in
                        Label {
                            Text(visibility.displayText)
                        } icon: {
                            Image(symbol: visibility.symbolImage)
                        }
                        .tag(visibility)
                        .labelStyle(.titleAndIcon)
                    }
                }
                .tint(.accentColor)

                Toggle(
                    String(
                        localized: "mark_share_fediverse_toggle", table: "Item"),
                    isOn: $viewModel.postToFediverse
                )
                .tint(.accentColor)
            }
            Section(header: Text("mark_advanced_view_advanced_settings_header", tableName: "Item", comment: "Mark - Header text for advanced settings section")) {
                Toggle(
                    String(
                        localized: "mark_change_date_toggle",
                        table: "Item",
                        comment:
                            "When mark is created, user can change the date, otherwise the date is the creation date. This is the toggle to change the date or not."
                    ),
                    isOn: $viewModel.changeTime
                )
                .tint(.accentColor)

                if viewModel.changeTime {
                    DatePicker(
                        String(
                            localized: "mark_change_date_picker_label",
                            table: "Item",
                            comment:
                                "When mark is created, user can change the date, otherwise the date is the creation date. This is the date of the changed date."
                        ),
                        selection: $viewModel.createdTime,
                        displayedComponents: [.date]
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
        .compositingGroup()
        .scrollContentBackground(.hidden)
        .navigationTitle(
            String(localized: "mark_advanced_view", table: "Item", comment: "Mark - Title for advanced view"))
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}
