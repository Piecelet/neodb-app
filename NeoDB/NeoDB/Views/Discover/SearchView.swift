//
//  SearchView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router
    
    var body: some View {
        searchContent
            .onAppear {
                viewModel.accountsManager = accountsManager
            }
            .onDisappear {
                viewModel.cleanup()
            }
    }
    
    private var searchContent: some View {
        List {
            searchResults
            loadingIndicator
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText)
        .onChange(of: viewModel.searchText) { _ in
            viewModel.search()
        }
        .navigationTitle("Search")
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var searchResults: some View {
        ForEach(viewModel.items, id: \.uuid) { item in
            Button {
                router.navigate(to: .itemDetailWithItem(item: item))
            } label: {
                ItemRowView(item: item)
            }
            .buttonStyle(.plain)
            .onAppear {
                if item == viewModel.items.last {
                    viewModel.loadMore()
                }
            }
        }
    }
    
    private var loadingIndicator: some View {
        Group {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(AppAccountsManager())
        .environmentObject(Router())
}

