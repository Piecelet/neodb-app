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

    func fetchFromURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            urlError = NSError(
                domain: "", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: String(
                        localized: "discover_search_invalid_url",
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

            // Set the result
            item = result
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

    var body: some View {
        Section {
            GroupBox(
                label: Label("Import from URL", systemImage: "link")
            ) {
                VStack(alignment: .leading, spacing: 20) {
                    PasteButton(payloadType: String.self) { strings in
                        guard let urlString = strings.first else { return }
                        Task { @MainActor in
                            viewModel.urlInput = urlString
                            await viewModel.fetchFromURL(urlString)
                        }
                    }

                    if viewModel.isShowingURLInput {
                        VStack(spacing: 12) {
                            HStack {
                                TextField(
                                    "Enter URL manually",
                                    text: $viewModel.urlInput
                                )
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .frame(minHeight: 40)

                                Button {
                                    Task {
                                        await viewModel.fetchFromURL(
                                            viewModel.urlInput)
                                    }
                                } label: {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.urlInput.isEmpty)
                            }

                            if viewModel.isLoadingURL {
                                ProgressView()
                            }

                            if let error = viewModel.urlError {
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                    } else {
                        Button {
                            withAnimation {
                                viewModel.isShowingURLInput = true
                            }
                        } label: {
                            Text("Manually Enter URL")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                    }

                    Spacer(minLength: 0)
                }
            }
//            .backgroundStyle(Color())
            .listRowSeparator(.hidden)
        }
        .task {
            viewModel.accountsManager = accountsManager
        }
        .onChange(of: viewModel.item) { item in
            if let item = item {
                HapticFeedback.selection()
                router.navigate(to: .itemDetailWithItem(item: item))
            }
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
