//
//  LoginView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import BetterSafariView
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showMastodonLogin = false
    let instance: MastodonInstance?
    let instanceAddress: String

    // Animation states
    @State private var buttonScale = 1.0

    init(instance: MastodonInstance? = nil, instanceAddress: String? = nil) {
        self.instance = instance
        self.instanceAddress = instanceAddress ?? AppConfig.defaultInstance
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
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                } else if let instance = instance ?? viewModel.instanceInfo {
                    VStack(alignment: .leading, spacing: 16) {
                        if let rules = instance.rules, !rules.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "login_instance_rules_title", table: "Settings"))
                                    .font(.headline)
                                
                                ForEach(rules) { rule in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(rule.text.asSafeMarkdownAttributedString)
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
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            buttonScale = 0.95
                        }

                        // Reset scale after brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                buttonScale = 1.0
                            }
                        }

                        Task {
                            await viewModel.authenticate()
                            accountsManager.isAuthenticating = true
                        }
                    }) {
                        HStack {
                            if accountsManager.isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "person.fill")
                                Text(String(format: String(localized: "login_button_signin_with", table: "Settings"), accountsManager.currentAccount.instance))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .scaleEffect(buttonScale)
                    .disabled(accountsManager.isAuthenticating)

                    Button {
                        showMastodonLogin = true
                    } label: {
                        HStack {
                            Image(symbol: .custom("custom.mastodon.fill"))
                            Text(String(localized: "mastodon_login_title", table: "Settings"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.mastodonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Text(String(localized: "login_instance_terms_notice", table: "Settings"))
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
            if instance == nil {
                await viewModel.loadInstanceInfo(instance: instanceAddress)
            }
        }
        .webAuthenticationSession(isPresented: $viewModel.isAuthenticating) {
            WebAuthenticationSession(
                url: viewModel.authUrl!,
                callbackURLScheme: AppConfig.OAuth.redirectUri
                    .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    ?? AppConfig.OAuth.redirectUri.replacingOccurrences(of: "://", with: "")
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
                MastodonLoginView()
            }
            .presentationDragIndicator(.visible)
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
