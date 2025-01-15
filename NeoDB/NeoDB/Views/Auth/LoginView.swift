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
    @State private var showInstanceInput = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("neodb-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("Welcome to NeoApp")
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
        
            Text("This is a open sourced third-party client for NeoDB made by citron.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .alert("Error", isPresented: $showError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .sheet(isPresented: $showInstanceInput) {
            InstanceInputView(selectedInstance: accountsManager.currentAccount.instance) { newInstance in
                let account = AppAccount(instance: newInstance, oauthToken: nil)
                accountsManager.add(account: account)
                showInstanceInput = false
            }
            .presentationDetents([.medium, .large])
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

struct InstanceInputView: View {
    @State private var selectedInstance: String
    @AppStorage(\.customInstance) private var customInstance: String
    @Environment(\.dismiss) private var dismiss
    
    let onSubmit: (String) -> Void
    
    private let instances = [
        (name: "NeoDB", host: "neodb.social", description: "一个自由、开放、互联的书籍、电影、音乐和游戏收藏评论交流社区。", tags: ["中文"]),
        (name: "Eggplant", host: "eggplant.place", description: "reviews about book, film, music, podcast and game.", tags: ["English", "Beta"]),
        (name: "ReviewDB", host: "reviewdb.app", description: "reviews about book, film, music, podcast and game.", tags: ["International"]),
        (name: "Minreol", host: "minreol.dk", description: "MinReol er et dansk fællesskab centreret om bøger, film, TV-serier, spil og podcasts.", tags: ["German"])
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
                        .foregroundStyle(.secondary)
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
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(instance.name)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text(instance.host)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(instance.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                    
                                    HStack(spacing: 4) {
                                        ForEach(instance.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
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
                    TextField("instance.social", text: $customInstance)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                        .onSubmit {
                            if !customInstance.isEmpty {
                                selectedInstance = customInstance
                                onSubmit(customInstance)
                                dismiss()
                            }
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                if selectedInstance == customInstance && !customInstance.isEmpty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 8)
                                }
                            }
                        )
                } header: {
                    Text("Custom Instance")
                } footer: {
                    Text("Enter your own instance URL if it's not listed above.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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

