//
//  TroubleshootingView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/28/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import KeychainSwift
import OSLog

@MainActor
class TroubleshootingViewModel: ObservableObject {
    private let logger = Logger.views.troubleshooting
    
    let instanceAddress: String
    
    @Published var isResettingClient = false
    @Published var resetSuccess = false
    @Published var error: Error?
    @Published var showError = false
    @Published var clientInfo: AppClient?
    
    init(instanceAddress: String) {
        self.instanceAddress = instanceAddress
        loadClientInfo()
    }
    
    func loadClientInfo() {
        do {
            clientInfo = try AppClient.retrieve(for: instanceAddress)
        } catch {
            logger.debug("No client found for instance: \(self.instanceAddress)")
            // Not showing an error as it's expected that there might not be a client
        }
    }
    
    func resetClient() async {
        isResettingClient = true
        defer { isResettingClient = false }
        
        do {
            // Delete existing client if any
            if let client = clientInfo {
                client.delete()
                logger.debug("Deleted client for instance: \(instanceAddress)")
            }
            
            // Clear any cached data related to this instance
            // This is a placeholder - implement according to your app's caching strategy
            
            resetSuccess = true
            clientInfo = nil
            logger.debug("Successfully reset client for instance: \(instanceAddress)")
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to reset client: \(error.localizedDescription)")
        }
    }
}

struct TroubleshootingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TroubleshootingViewModel
    @State private var showResetClientAlert = false
    
    init(instanceAddress: String) {
        _viewModel = StateObject(wrappedValue: TroubleshootingViewModel(
            instanceAddress: instanceAddress
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instance")
                            .font(.headline)
                        Text(viewModel.instanceAddress)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Instance Information")
                }
                
                Section {
                    if let client = viewModel.clientInfo {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Client ID: \(client.clientId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Client Secret: \(client.clientSecret)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let vapidKey = client.vapidKey {
                                Text("Vapid Key: \(vapidKey)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("No client information found")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        showResetClientAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                            Text("Reset Client")
                        }
                    }
                    .disabled(viewModel.isResettingClient)
                } header: {
                    Text("Client Information")
                } footer: {
                    Text("Resetting the client will clear all OAuth client information for this instance. You'll need to sign in again.")
                }
                
                Section {
                    NavigationLink {
                        DeveloperView()
                    } label: {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("Developer Tools")
                        }
                    }
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Access developer tools for more advanced troubleshooting options.")
                }
                
                if viewModel.resetSuccess {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Client successfully reset")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .refreshable {
                viewModel.loadClientInfo()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
            .confirmationDialog(
                "Reset Client",
                isPresented: $showResetClientAlert,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    Task {
                        await viewModel.resetClient()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete the OAuth client for this instance. You'll need to sign in again. This action cannot be undone.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .enableInjection()
    }
    
    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
