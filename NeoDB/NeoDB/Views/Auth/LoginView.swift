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
            InstanceInputView(selectedInstance: instanceUrl) { newInstance in
                let account = AppAccount(instance: newInstance, oauthToken: nil)
                accountsManager.add(account: account)
                instanceUrl = newInstance
                showInstanceInput = false
            }
            .presentationDetents([.medium])
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

struct InstanceInputView: View {
    @State private var selectedInstance: String
    @State private var customInstance: String = ""
    @Environment(\.dismiss) private var dismiss
    
    let onSubmit: (String) -> Void
    
    private let instances = [
        (name: "NeoDB", host: "neodb.social", description: "中文"),
        (name: "Eggplant", host: "eggplant.place", description: "English Test Server"),
        (name: "ReviewDB", host: "reviewdb.app", description: "International"),
        (name: "Minreol", host: "minreol.dk", description: "German")
    ]
    
    init(selectedInstance: String, onSubmit: @escaping (String) -> Void) {
        _selectedInstance = State(initialValue: selectedInstance)
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text("Select Instance")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
            .padding()
            
            List {
                Section {
                    ForEach(instances, id: \.host) { instance in
                        Button(action: {
                            selectedInstance = instance.host
                            onSubmit(instance.host)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(instance.name)
                                        .font(.body)
                                    Text(instance.host)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(instance.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedInstance == instance.host {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Choose an Instance")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter custom instance", text: $customInstance)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                        
                        Button(action: {
                            if !customInstance.isEmpty {
                                selectedInstance = customInstance
                                onSubmit(customInstance)
                                dismiss()
                            }
                        }) {
                            Text("Use Custom Instance")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(customInstance.isEmpty)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Custom Instance")
                } footer: {
                    Text("Enter your own instance URL if it's not listed above.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(.ultraThinMaterial)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

