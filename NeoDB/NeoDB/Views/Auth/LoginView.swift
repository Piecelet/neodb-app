//
//  LoginView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import BetterSafariView
import SwiftUI
import os

struct LoginView: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isAddingAccount) private var isAddingAccount
    @StateObject private var viewModel: LoginViewModel
    @State private var showMastodonLogin = false
    @State private var canDismiss = false
    private let logger = Logger.views.login

    init(instance: MastodonInstance? = nil, instanceAddress: String? = nil) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(
            instance: instance,
            instanceAddress: instanceAddress
        ))
        logger.debug("LoginView initialized with instance: \(String(describing: instance))")
    }

    private var signInButton: some View {
        Button(action: {
            viewModel.handleSignInButtonTap()
        }) {
            HStack {
                if accountsManager.isAuthenticating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.fill")
                    Text(
                        String(
                            format: String(
                                localized: "login_button_signin_with",
                                table: "Settings"),
                            accountsManager.currentAccount.instance))
                }
            }
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding()
            .buttonStyle(.borderedProminent)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .scaleEffect(viewModel.buttonScale)
        .disabled(accountsManager.isAuthenticating)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("piecelet-symbol")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    Text(accountsManager.currentAccount.instance)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.grayBackground)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                } else if let instance = viewModel.instance ?? viewModel.instanceInfo {
                    VStack(alignment: .leading, spacing: 16) {
                        if let rules = instance.rules, !rules.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(
                                    String(
                                        localized: "login_instance_rules_title",
                                        table: "Settings")
                                )
                                .font(.headline)

                                ForEach(rules) { rule in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(
                                            rule.text
                                                .asSafeMarkdownAttributedString
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                signInButton

                Button {
                    showMastodonLogin = true
                } label: {
                    HStack {
                        Image(symbol: .custom("custom.mastodon.fill"))
                        Text(
                            String(
                                localized: "mastodon_login_title",
                                table: "Settings"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.mastodonPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text(
                    String(
                        localized: "login_instance_terms_notice",
                        table: "Settings")
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.top)
            .background(.bar)
        }
        .navigationTitle(String(localized: "login_title", table: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(!viewModel.canDismiss && isAddingAccount)
        .onAppear {
            logger.debug("LoginView appeared, isAddingAccount: \(isAddingAccount), canDismiss: \(canDismiss)")
            if !isAddingAccount {
                canDismiss = true
            }
        }
        .onDisappear {
            if isAddingAccount {
                logger.debug("LoginView disappearing, restoring last authenticated account")
                accountsManager.restoreLastAuthenticatedAccount()
                canDismiss = true
                logger.debug("LoginView disappeared, canDismiss set to true")
            }
        }
        .alert(
            "Error", isPresented: $viewModel.showError,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        )
        .task {
            viewModel.accountsManager = accountsManager
            if viewModel.instance == nil {
                viewModel.updateInstance(viewModel.instanceAddress)
            }
        }
        .webAuthenticationSession(isPresented: $viewModel.isAuthenticating) {
            WebAuthenticationSession(
                url: viewModel.authUrl!,
                callbackURLScheme: AppConfig.OAuth.redirectUri
                    .addingPercentEncoding(
                        withAllowedCharacters: .urlHostAllowed)
                    ?? AppConfig.OAuth.redirectUri.replacingOccurrences(
                        of: "://", with: "")
            ) { callbackURL, error in
                if let url = callbackURL {
                    Task {
                        viewModel.isAuthenticating = true
                        try? await viewModel.handleCallback(url: url)
                    }
                }
                viewModel.isAuthenticating = false
            }
        }
        .sheet(isPresented: $showMastodonLogin) {
            NavigationStack {
                VStack(spacing: 0) {
                    HStack {
                        Text("mastodon_login_title", tableName: "Settings")
                            .font(.headline)
                        Spacer()
                        Button(action: { showMastodonLogin = false }) {
                            Image(systemSymbol: .xmarkCircleFill)
                                .font(.title2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()

                    Spacer()

                    VStack(spacing: 16) {
                        Image(symbol: .custom("custom.fediverse"))
                            .font(.system(size: 60))
                            .foregroundStyle(Color(.systemGray))

                        VStack(spacing: 8) {
                            Text("mastodon_guide_title", tableName: "Settings")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text(
                                String(
                                    format: String(
                                        localized: "mastodon_guide_subtitle",
                                        table: "Settings"),
                                    String(
                                        format: String(
                                            localized:
                                                "login_button_signin_with",
                                            table: "Settings"),
                                        accountsManager.currentAccount.instance)
                                )
                            )
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        }
                        Image("mastodon.instruction")
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)

                    Spacer()

                    signInButton
                        .padding()
                }
                .background(.ultraThinMaterial)
            }
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.visible)
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
