//
//  SearchURLView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct SearchURLView: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject private var router: Router
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                if viewModel.isShowingURLInput {
                    manualInputView
                } else {
                    urlInputButtons
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("discover_search_url_section", tableName: "Discover")
        }
        .onChange(of: viewModel.searchState) { state in
            if case .results(let items) = state, let item = items.first {
                HapticFeedback.selection()
                router.navigate(to: .itemDetailWithItem(item: item))
            }
        }
    }
    
    private var manualInputView: some View {
        VStack(spacing: 8) {
            HStack {
                TextField(String(localized: "discover_search_url_input_placeholder", table: "Discover"), text: $viewModel.urlInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button {
                    Task {
                        await viewModel.fetchFromURL(viewModel.urlInput)
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(viewModel.urlInput.isEmpty ? .secondary : .blue)
                }
                .disabled(viewModel.urlInput.isEmpty)
            }
            
            if viewModel.isLoadingURL {
                ProgressView()
            }
            
            if let error = viewModel.urlError {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }
    
    private var urlInputButtons: some View {
        HStack {
            HStack {
                PasteButton(payloadType: String.self) { strings in
                    guard let urlString = strings.first else { return }
                    Task { @MainActor in
                        viewModel.urlInput = urlString
                        await viewModel.fetchFromURL(urlString)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Text("discover_search_paste_url", tableName: "Discover")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button {
                viewModel.isShowingURLInput = true
            } label: {
                Image(systemName: "keyboard")
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    List {
        SearchURLView(viewModel: SearchViewModel())
            .environmentObject(Router())
    }
}

