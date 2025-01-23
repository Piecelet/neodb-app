//
//  MastodonLoginView.swift
//  NeoDB
//
//  Created by citron on 2/10/25.
//

import AuthenticationServices
import SwiftUI
import WebView

struct MastodonLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountsManager: AppAccountsManager

    @StateObject private var viewModel = MastodonLoginViewModel()
    @StateObject private var webViewStore = WebViewStore()

    // Animation states
    @State private var inputScale = 0.9
    @State private var contentOpacity = 0.0

    var body: some View {
        VStack(spacing: 0) {
            Form {
                logoView

                // Top Section
                if viewModel.currentStep == 1 {
                    mastodonInstanceInput
                } else {
                    neodbInstanceInput
                }

                // Middle Section (Action Button)
                Section {
                    actionButton
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // Bottom Section
                if viewModel.currentStep == 1 {
                    mastodonInstanceDetail
                } else {
                    neodbInstanceActions
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(
            viewModel.currentStep == 2
                ? "Choose NeoDB Instance" : "Sign In with Mastodon"
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemSymbol: .chevronLeft) {
                    dismiss()
                }
                .labelStyle(.iconOnly)
            }
            ToolbarItem(placement: .principal) {
                Text(
                    viewModel.currentStep == 2
                        ? "Choose NeoDB Instance" : "Sign In with Mastodon"
                )
                .font(.headline)
            }
        }
        .sheet(isPresented: $viewModel.showInstanceInput) {
            InstanceInputView(
                selectedInstance: accountsManager.currentAccount.instance
            ) { newInstance in
                viewModel.updateNeoDBInstance(newInstance)
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadInitialInstances()
        }
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
        .enableInjection()
    }

    // MARK: - Logo
    private var logoView: some View {
        Section {
            Group {
                if viewModel.currentStep == 1 {
                    Image("mastodon-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                } else {
                    Image("neodb-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Top Section Views
    private var mastodonInstanceInput: some View {
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
    }

    private var neodbInstanceInput: some View {
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
    }

    // MARK: - Bottom Section Views
    private var mastodonInstanceDetail: some View {
        Group {
            if let instance = viewModel.selectedMastodonInstance {
                instanceDetailSection(instance)
                instanceRulesSection(instance)
            } else if !viewModel.filteredInstances.isEmpty {
                popularInstancesSection
            }
        }
    }

    private var neodbInstanceActions: some View {
        Section {
            Button(role: .cancel) {
                withAnimation {
                    viewModel.currentStep = 1
                }
            } label: {
                Label(
                    "Change Mastodon Instance", systemSymbol: .chevronLeft
                )
                .labelStyle(.titleAndIcon)
                .padding(.vertical, 4)
                .foregroundColor(.secondary)
            }
        }
    }

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

    private var actionButton: some View {
        Button(action: {
            if viewModel.currentStep == 1 {
                if viewModel.validateAndContinue() {
                    withAnimation {
                        viewModel.currentStep = 2
                    }
                }
            } else {
                Task {
                    await viewModel.authenticate()
                }
            }
        }) {
            HStack {
                if viewModel.isLoading || viewModel.isAuthenticating {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.isInstanceUnavailable {
                    Text("Unavailable")
                } else {
                    if #available(iOS 17.0, *), viewModel.currentStep == 2 {
                        Image(systemSymbol: .personBubble)
                    }
                    Text(
                        viewModel.currentStep == 1
                            ? "Continue"
                            : "Sign In with \(viewModel.mastodonInstance)"
                    )
                    if viewModel.currentStep == 1 {
                        Image(systemSymbol: .arrowRight)
                    }
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
                || (viewModel.currentStep == 1
                    && (viewModel.mastodonInstance.isEmpty
                        || viewModel.selectedMastodonInstance == nil))
        )
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
