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
    
    // Animation states
    @State private var buttonScale = 1.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "login_instance_title", table: "Settings"))
                        .font(.headline)
                    
                    HStack {
                        Text(accountsManager.currentAccount.instance)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(String(localized: "login_instance_change", table: "Settings")) {
                            withAnimation {
                                viewModel.showInstanceInput = true
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
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
                    
                    NavigationLink {
                        MastodonLoginView()
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
                }
                .padding(.horizontal)
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
            .sheet(isPresented: $viewModel.showInstanceInput) {
                InstanceInputView(
                    selectedInstance: accountsManager.currentAccount.instance
                ) { newInstance in
                    withAnimation {
                        viewModel.updateInstance(newInstance)
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                viewModel.accountsManager = accountsManager
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
            .enableInjection()
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
