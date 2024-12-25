//
//  ContentView.swift
//  NeoDB
//
//  Created by citron on 12/14/24.
//

import SwiftUI
import Account
import Network
import Config

struct ContentView: View {
    @StateObject private var accountManager = AccountManager()
    @State private var server = ServerConfiguration.defaultServer
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        Group {
            if accountManager.isAuthenticated {
                // Main app content
                VStack {
                    if let user = accountManager.currentUser {
                        AsyncImage(url: URL(string: user.avatar)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .foregroundColor(.gray)
                                .frame(width: 100, height: 100)
                        }
                        
                        Text(user.displayName)
                            .font(.title2)
                        Text(user.externalAcct)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Sign Out") {
                        accountManager.signOut()
                    }
                    .padding()
                }
            } else {
                // Login view
                VStack(spacing: 20) {
                    Text("Welcome to NeoDB")
                        .font(.largeTitle)
                    
                    TextField("Server", text: $server)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal)
                    
                    Button {
                        Task {
                            await signIn()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
                    Button("Reset to Default Server") {
                        server = ServerConfiguration.defaultServer
                    }
                    .disabled(server == ServerConfiguration.defaultServer)
                }
                .padding()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func signIn() async {
        isLoading = true
        error = nil
        
        do {
            accountManager.updateServer(server)
            try await accountManager.signIn()
        } catch {
            self.error = error
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
}
