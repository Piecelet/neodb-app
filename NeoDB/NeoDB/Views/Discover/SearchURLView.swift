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
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Text("Import from URL")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
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
                            TextField("Enter URL manually", text: $viewModel.urlInput)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .frame(minHeight: 40)
                            
                            Button {
                                Task {
                                    await viewModel.fetchFromURL(viewModel.urlInput)
                                }
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                            }
//                            .buttonStyle(PrimaryButtonStyle())
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
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .onChange(of: viewModel.searchState) { state in
            if case .results(let items) = state, let item = items.first {
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
        SearchURLView(viewModel: SearchViewModel())
            .environmentObject(Router())
    }
}
