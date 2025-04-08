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
                Text(String(localized: "troubleshooting_intro", table: "Settings"))
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.instanceAddress)
                            .font(.headline)
                        if let client = viewModel.clientInfo {
                            Text(verbatim: "Client ID: \(client.clientId)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(String(localized: "troubleshooting_no_client", table: "Settings"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showResetClientAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                            Text(String(localized: "troubleshooting_reset_client", table: "Settings"))
                        }
                    }
                    .disabled(viewModel.isResettingClient || viewModel.clientInfo == nil)
                } header: {
                    Text(String(localized: "troubleshooting_instance_header", table: "Settings"))
                } footer: {
                    Text(String(localized: "troubleshooting_reset_footer", table: "Settings"))
                }
                
                // Contact Section
                Section {
                    Link(destination: URL(string: "mailto:contact@piecelet.app")!) {
                        HStack {
                            Label(String(localized: "about_email", table: "Settings"), systemImage: "envelope")
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
                            Text(String(localized: "app_feature_requests", table: "Settings"))
                        } icon: {
                            Image(systemName: "lightbulb")
                        }
                    }
                } header: {
                    Text(String(localized: "troubleshooting_contact_header", table: "Settings"))
                } footer: {
                    Text(String(localized: "troubleshooting_contact_footer", table: "Settings"))
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
                        Text(String(localized: "troubleshooting_no_client_info", table: "Settings"))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(String(localized: "troubleshooting_client_info_header", table: "Settings"))
                }
                
                Section {
                    NavigationLink {
                        DeveloperView()
                    } label: {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text(String(localized: "developer_title", table: "Settings"))
                        }
                    }
                } header: {
                    Text(String(localized: "troubleshooting_advanced_header", table: "Settings"))
                }
                #endif
                
                if viewModel.resetSuccess {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(String(localized: "troubleshooting_reset_success", table: "Settings"))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "troubleshooting_title", table: "Settings"))
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
            .alert(String(localized: "troubleshooting_error_title", table: "Settings"), isPresented: $viewModel.showError) {
                Button(String(localized: "troubleshooting_ok", table: "Settings"), role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? String(localized: "troubleshooting_unknown_error", table: "Settings"))
            }
            .confirmationDialog(
                String(localized: "troubleshooting_reset_client", table: "Settings"),
                isPresented: $showResetClientAlert,
                titleVisibility: .visible
            ) {
                Button(String(localized: "troubleshooting_reset_confirm", table: "Settings"), role: .destructive) {
                    Task {
                        await viewModel.resetClient()
                    }
                }
                Button(String(localized: "troubleshooting_cancel", table: "Settings"), role: .cancel) {}
            } message: {
                Text(String(localized: "troubleshooting_reset_warning", table: "Settings"))
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
