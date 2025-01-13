//
//  LoginView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var accountsManager: AppAccountsManager
    @Environment(\.openURL) private var openURL
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var instanceUrl: String = "neodb.social"
    @State private var showInstanceInput = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("neodb-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("Welcome to NeoDB")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Track and share your books, movies, music, and more")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Instance")
                    .font(.headline)
                
                HStack {
                    Text(accountsManager.currentAccount.instance)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Change") {
                        showInstanceInput = true
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                Task {
                    do {
                        let authUrl = try await accountsManager.authenticate(instance: accountsManager.currentAccount.instance)
                        openURL(authUrl)
                    } catch AccountError.invalidURL {
                        errorMessage = "Invalid instance URL"
                        showError = true
                    } catch AccountError.registrationFailed(let message) {
                        errorMessage = "Registration failed: \(message)"
                        showError = true
                    } catch AccountError.authenticationFailed(let message) {
                        errorMessage = "Authentication failed: \(message)"
                        showError = true
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }) {
                HStack {
                    if accountsManager.isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.fill")
                        Text("Sign in with NeoDB")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(accountsManager.isAuthenticating)
            .padding(.horizontal)
        }
        .padding()
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .sheet(isPresented: $showInstanceInput) {
            NavigationStack {
                InstanceInputView(instanceUrl: instanceUrl) { newInstance in
                    let account = AppAccount(instance: newInstance, oauthToken: nil)
                    accountsManager.add(account: account)
                    instanceUrl = newInstance
                    showInstanceInput = false
                }
                .navigationTitle("Change Instance")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showInstanceInput = false
                    }
                )
            }
            .presentationDetents([.height(200)])
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

struct InstanceInputView: View {
    @State private var instanceUrl: String
    @State private var isValidating = false
    @State private var localError: String?
    @FocusState private var isUrlFieldFocused: Bool
    
    let onSubmit: (String) -> Void
    
    init(instanceUrl: String, onSubmit: @escaping (String) -> Void) {
        _instanceUrl = State(initialValue: instanceUrl)
        self.onSubmit = onSubmit
    }
    
    var isValidUrl: Bool {
        let urlPattern = "^[a-zA-Z0-9][a-zA-Z0-9-_.]+\\.[a-zA-Z]{2,}$"
        let urlPredicate = NSPredicate(format: "SELF MATCHES %@", urlPattern)
        return urlPredicate.evaluate(with: instanceUrl)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Enter the URL of your NeoDB instance")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Instance URL", text: $instanceUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .submitLabel(.done)
                .focused($isUrlFieldFocused)
                .onChange(of: instanceUrl) { _ in
                    localError = nil
                }
                .onSubmit {
                    submitInstance()
                }
                .accessibilityHint("Enter your NeoDB instance URL, for example: neodb.social")
            
            if let error = localError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: submitInstance) {
                HStack {
                    if isValidating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Connect")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isValidating || instanceUrl.isEmpty || !isValidUrl)
        }
        .padding()
        .onAppear {
            isUrlFieldFocused = true
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
    
    private func submitInstance() {
        guard isValidUrl else {
            localError = "Please enter a valid instance URL"
            return
        }
        
        isValidating = true
        onSubmit(instanceUrl)
        isValidating = false
    }
}
