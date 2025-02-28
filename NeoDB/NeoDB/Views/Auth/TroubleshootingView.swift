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
import WishKit

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
    @Environment(\.openURL) private var openURL
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
                Text("If you're having trouble signing in, please try reset client.")
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.instanceAddress)
                            .font(.headline)
                        if let client = viewModel.clientInfo {
                            Text(verbatim: "Client ID: \(client.clientId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(verbatim: "No registered client.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showResetClientAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                            Text("Reset Client")
                        }
                    }
                    .disabled(viewModel.isResettingClient || viewModel.clientInfo == nil)
                } header: {
                    Text("Instance")
                } footer: {
                    Text("Resetting the client will clear all OAuth client information for this instance. You may need to sign in again.")
                }
                
                // Contact Section
                Section {
                    Link(destination: URL(string: "mailto:contact@piecelet.app")!) {
                        HStack {
                            Label("Email", systemImage: "envelope")
                            Spacer()
                            Text("contact@piecelet.app")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://mastodon.social/@piecelet")!) {
                        HStack {
                            Label(String(localized: "about_social_mastodon", table: "Settings"), systemImage: "bubble.left")
                            Spacer()
                            Text("@piecelet")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://m.cmx.im/@piecelet")!) {
                        HStack {
                            Label(String(localized: "about_social_mastodon_cn", table: "Settings"), systemImage: "bubble.left")
                            Spacer()
                            Text("@piecelet")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        WishKitView()
                    } label: {
                        Label {
                            Text("app_feature_requests", tableName: "Settings")
                        } icon: {
                            Image(systemName: "lightbulb")
                        }
                    }
                } header: {
                    Text("Contact & Feedback")
                } footer: {
                    Text("If you need further assistance, please contact us or submit feedback.")
                }
                
                #if DEBUG
                
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
                } header: {
                    Text("Client Information")
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
                #endif
                
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
            .navigationTitle("Need Help?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .foregroundStyle(.secondary)
                }
            }
            // .refreshable {
            //    viewModel.loadClientInfo()
            // }
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
        .presentationDragIndicator(.hidden)
        .enableInjection()
    }
    
    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
