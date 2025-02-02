//
//  SearchURLView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI

@MainActor
class SearchURLViewModel: ObservableObject {
    private let logger = Logger.views.discover.searchURL

    @Published var urlInput = ""
    @Published var isShowingURLInput = false
    @Published var isLoadingURL = false
    @Published var urlError: Error?
    @Published private(set) var item: ItemSchema?

    var accountsManager: AppAccountsManager?
    var router: Router?

    func fetchFromURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            urlError = NSError(
                domain: "", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: String(
                        localized: "discover_search_url_invalid_url",
                        table: "Discover")
                ])
            return
        }

        isLoadingURL = true
        urlError = nil

        do {
            guard let accountsManager = accountsManager else { return }
            let endpoint = CatalogEndpoint.fetch(url: url)
            let result = try await accountsManager.currentClient.fetch(
                endpoint, type: ItemSchema.self)

            // Reset states
            isLoadingURL = false
            isShowingURLInput = false
            urlInput = ""

            // Set the result and navigate
            item = result
            HapticFeedback.selection()
            router?.navigate(to: .itemDetailWithItem(item: result))
        } catch {
            urlError = error
            isLoadingURL = false
        }
    }
}

struct SearchURLView: View {
    @StateObject private var viewModel = SearchURLViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 16) {

                VStack(alignment: .center, spacing: 12) {
                    Label(String(localized: "discover_search_url_title", table: "Discover"), systemImage: "link")
                        .font(.headline)
                        .labelStyle(.titleOnly)

                    HStack(spacing: 4) {
                        Image("discover.searchURL.douban")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.books")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.movies")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.music")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.games")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                    }
                }

                HStack(spacing: 8) {
                    ZStack(alignment: .trailing) {
                        TextField(
                            String(localized: "discover_search_url_input_placeholder", table: "Discover"),
                            text: $viewModel.urlInput
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .padding(.horizontal)
                        .padding(.trailing, 50)
                        .background(
                            colorScheme == .light
                                ? AnyShapeStyle(Color.white)
                                : AnyShapeStyle(.ultraThinMaterial)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Group {
                            if viewModel.urlInput.isEmpty {
                                PasteButton(payloadType: String.self) {
                                    strings in
                                    guard let urlString = strings.first
                                    else { return }
                                    Task { @MainActor in
                                        viewModel.urlInput = urlString
                                        await viewModel.fetchFromURL(
                                            urlString)
                                    }
                                }
                                .buttonBorderShape(.capsule)
                                .labelStyle(.iconOnly)
                            } else {
                                Button {
                                    Task {
                                        await viewModel.fetchFromURL(
                                            viewModel.urlInput)
                                    }
                                } label: {
                                    Group {
                                        if viewModel.isLoadingURL {
                                            ProgressView()
                                                .tint(.white)
                                                .controlSize(.small)
                                        } else {
                                            Label(
                                                String(localized: "discover_search_url_submit_button", table: "Discover"),
                                                systemSymbol: .arrowRight
                                            )
                                            .labelStyle(.iconOnly)
                                        }
                                    }
                                    .font(.headline)
                                    .frame(height: 20)
                                }
                                .buttonStyle(.borderedProminent)
                                .buttonBorderShape(.capsule)
                            }
                        }
                        .padding(.trailing, 12)
                    }
                }
                .frame(maxWidth: .infinity)

                if !viewModel.urlInput.isEmpty && !viewModel.isLoadingURL {
                    Button(
                        String(localized: "discover_search_url_clear_button", table: "Discover"),
                        systemSymbol: .xmark
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.urlInput = ""
                        }
                    }
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.plain)
                }

                if let error = viewModel.urlError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.grayBackground)
            .listRowSeparator(.hidden)
        }
        .task {
            viewModel.accountsManager = accountsManager
            viewModel.router = router
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    List {
        SearchURLView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}
