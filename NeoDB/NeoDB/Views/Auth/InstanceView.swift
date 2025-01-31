//
//  InstanceView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct InstanceView: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LoginViewModel()
    @State private var searchText = ""
    @AppStorage(\.customInstance) private var customInstance: String

    private let instances = AppConfig.instances

    var filteredInstances: [AppInstance] {
        if searchText.isEmpty {
            return instances
        }
        return instances.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.host.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredInstances, id: \.host) { instance in
                    NavigationLink {
                        LoginView()
                            .onAppear {
                                viewModel.updateInstance(instance.host)
                            }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text(instance.name)
                                    .font(.headline)
                                Text(instance.host)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemSymbol: .personFill)
                                        .foregroundColor(.secondary)
                                    Text(instance.users)
                                }

                                HStack(spacing: 4) {
                                    Image(systemSymbol: .tagFill)
                                        .foregroundColor(.secondary)
                                    Text(
                                        instance.tags.joined(
                                            separator: ", "))
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)

                            Text(instance.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 16) {
                TextField("Community Name or URL...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(.secondary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.plain)
        .task {
            viewModel.accountsManager = accountsManager
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
