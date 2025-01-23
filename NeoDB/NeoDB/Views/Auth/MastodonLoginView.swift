//
//  MastodonLoginView.swift
//  NeoDB
//
//  Created by citron on 2/10/25.
//

import SwiftUI
import WebView

struct MastodonLoginView: View {
    @StateObject private var viewModel = MastodonLoginViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var webViewStore = WebViewStore()
    
    var body: some View {
        NavigationStack {
            // Step 1: Choose Mastodon Instance
            MastodonInstanceView(viewModel: viewModel)
                .navigationTitle("Sign In with Mastodon")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $viewModel.isWebViewPresented) {
                    NavigationView {
                        ZStack(alignment: .top) {
                            WebView(webView: webViewStore.webView)
                            
                            if webViewStore.isLoading {
                                ProgressView()
                                    .progressViewStyle(.linear)
                                    .tint(.accentColor)
                            }
                        }
                        .navigationBarTitle("Sign In", displayMode: .inline)
                        .navigationBarItems(leading: Button("Cancel") {
                            viewModel.isWebViewPresented = false
                            viewModel.isAuthenticating = false
                            webViewStore.webView.stopLoading()
                        })
                    }
                    .onAppear {
                        webViewStore.webView.navigationDelegate = viewModel
                        if let request = viewModel.webViewRequest {
                            webViewStore.webView.load(request)
                        }
                    }
                    .interactiveDismissDisabled()
                }
                .task {
                    viewModel.accountsManager = accountsManager
                    await viewModel.loadInitialInstances()
                }
        }
        .enableInjection()
    }
}

// MARK: - Mastodon Instance View
struct MastodonInstanceView: View {
    @ObservedObject var viewModel: MastodonLoginViewModel
    
    var body: some View {
        Form {
            Section {
                Image("mastodon-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            Section {
                TextField("mastodon.social", text: $viewModel.mastodonInstance)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.mastodonInstance) { _ in
                        viewModel.searchInstances()
                    }
            } header: {
                Text("Mastodon Instance")
            }
            
            Section {
                NavigationLink {
                    NeoDBInstanceView(viewModel: viewModel)
                } label: {
                    HStack {
                        if viewModel.isLoading || viewModel.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else if viewModel.isInstanceUnavailable {
                            Text("Unavailable")
                        } else {
                            Text("Continue")
                            Image(systemSymbol: .arrowRight)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(
                    viewModel.isLoading
                        || viewModel.isAuthenticating
                        || viewModel.isInstanceUnavailable
                        || viewModel.mastodonInstance.isEmpty
                        || viewModel.selectedMastodonInstance == nil
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            if let instance = viewModel.selectedMastodonInstance {
                instanceDetailSection(instance)
                instanceRulesSection(instance)
            } else if !viewModel.filteredInstances.isEmpty {
                popularInstancesSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    // MARK: - Instance Detail Components
    private func instanceDetailSection(_ instance: MastodonInstance)
        -> some View
    {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(instance.title)
                        .font(.headline)
                    Text(viewModel.mastodonInstance)
                        .foregroundStyle(.secondary)
                }
                Text(instance.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Users")
                Spacer()
                Text("\(instance.stats.userCount) users")
            }
            .foregroundStyle(.secondary)
            .font(.subheadline)

            HStack {
                Text("Posts")
                Spacer()
                Text("\(instance.stats.statusCount) posts")
            }
            .foregroundStyle(.secondary)
            .font(.subheadline)

            HStack {
                Text("Links")
                Spacer()
                Text("\(instance.stats.domainCount) links")
            }
            .foregroundStyle(.secondary)
            .font(.subheadline)
        } header: {
            Text("Instance Details")
        }
    }

    private func instanceRulesSection(_ instance: MastodonInstance) -> some View
    {
        Group {
            if let rules = instance.rules, !rules.isEmpty {
                Section {
                    ForEach(Array(rules.enumerated()), id: \.element.id) {
                        index, rule in
                        HStack(alignment: .top, spacing: 6) {
                            Image(
                                systemName: index <= 50
                                    ? "\(index + 1).circle" : "info.circle"
                            )
                            .padding(.top, 4)
                            .foregroundStyle(.accent)
                            Text(rule.text)
                                .font(.subheadline)
                                .padding(.vertical, 4)
                        }
                    }
                    .listRowInsets(
                        EdgeInsets(
                            top: 11, leading: 11, bottom: 11, trailing: 20))
                } header: {
                    Text("Instance Rules")
                }
            }
        }
    }

    private var popularInstancesSection: some View {
        Section {
            ForEach(viewModel.filteredInstances) { instance in
                Button {
                    viewModel.selectInstance(instance)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(instance.domain)
                            Spacer()
                            Text("\(instance.totalUsers) users")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Text(instance.description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .foregroundColor(.primary)
            }
        } header: {
            Text("Popular Instances")
        }
    }
}

// MARK: - NeoDB Instance View
struct NeoDBInstanceView: View {
    @ObservedObject var viewModel: MastodonLoginViewModel
    @EnvironmentObject private var accountsManager: AppAccountsManager
    
    var body: some View {
        Form {
            Section {
                Image("neodb-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            Section {
                HStack {
                    Text(accountsManager.currentAccount.instance)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Change") {
                        withAnimation {
                            viewModel.showInstanceInput = true
                        }
                    }
                }
            } header: {
                Text("NeoDB Instance")
            }
            
            Section {
                Button(action: {
                    Task {
                        await viewModel.authenticate()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading || viewModel.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            if #available(iOS 17.0, *) {
                                Image(systemSymbol: .personCircle)
                            }
                            Text("Sign In with \(viewModel.mastodonInstance)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isLoading || viewModel.isAuthenticating)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Choose NeoDB Instance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showInstanceInput) {
            InstanceInputView(
                selectedInstance: accountsManager.currentAccount.instance
            ) { newInstance in
                viewModel.updateNeoDBInstance(newInstance)
            }
            .presentationDetents([.medium, .large])
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
