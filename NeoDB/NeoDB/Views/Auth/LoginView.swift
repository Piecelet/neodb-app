//
//  LoginView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import AuthenticationServices
import BetterSafariView
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LoginViewModel()
    
    // Animation states
    @State private var logoScale = 0.5
    @State private var contentOpacity = 0.0
    @State private var titleOffset = CGFloat(50)
    @State private var buttonScale = 1.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("piecelet-symbol")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: logoScale)
                
                Text("Welcome to Piecelet")
                    .font(.title)
                    .fontWeight(.bold)
                    .offset(y: titleOffset)
                    .opacity(contentOpacity)
                
                Text("Track and share your books, movies, music, and more")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(contentOpacity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instance")
                        .font(.headline)
                    
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
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .opacity(contentOpacity)
                
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
                                Text("Sign in with \(accountsManager.currentAccount.instance)")
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
                            Text("Sign in with Mastodon")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.mastodonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
                .opacity(contentOpacity)
                
                Text("Piecelet is a open sourced third-party client for NeoDB made by citron.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(contentOpacity)
            }
            .padding()
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
                
                // Trigger animations
                withAnimation(.easeOut(duration: 0.6)) {
                    logoScale = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    contentOpacity = 1.0
                    titleOffset = 0
                }
            }
            .webAuthenticationSession(isPresented: $accountsManager.isAuthenticating) {
                WebAuthenticationSession(
                    url: viewModel.authUrl!,
                    callbackURLScheme: AppConfig.OAuth.redirectUri
                        .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                        ?? AppConfig.OAuth.redirectUri.replacingOccurrences(of: "://", with: "")
                ) { callbackURL, error in
                    if let url = callbackURL {
                        Task {
                            try? await viewModel.handleCallback(url: url)
                        }
                    }
                    accountsManager.isAuthenticating = false
                }
            }
        }
        .enableInjection()
    }
    
    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
