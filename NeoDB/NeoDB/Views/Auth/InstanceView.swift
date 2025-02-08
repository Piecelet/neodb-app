//
//  InstanceView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Kingfisher
import OSLog
import SwiftUI

private struct IsAddingAccountKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isAddingAccount: Bool {
        get { self[IsAddingAccountKey.self] }
        set { self[IsAddingAccountKey.self] = newValue }
    }
}

// 定义图标类型枚举
private enum IconType {
    case globe
    case tag

    var systemName: String {
        switch self {
        case .globe: return "globe"
        case .tag: return "tag.fill"
        }
    }
}

struct InstanceView: View {
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var instanceViewModel = InstanceViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showLoginView = false
    @AppStorage(\.customInstance) private var customInstance: String
    let isAddingAccount: Bool
    private let logger = Logger.views.login

    private let instances = AppConfig.instances

    private var filteredInstances: [AppInstance] {
        if searchText.isEmpty {
            return instances
        }
        return instances.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.host.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    init(isAddingAccount: Bool = false) {
        self.isAddingAccount = isAddingAccount
    }

    var body: some View {
        List {
            if instanceViewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .id(UUID())
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                .listSectionSeparator(.hidden, edges: .bottom)
            }

            if let instance = instanceViewModel.instanceInfo,
                !instances.contains(where: { $0.host == searchText })
            {
                Section {
                    if instanceViewModel.isCompatible {
                        Button {
                            let account = AppAccount(instance: searchText, oauthToken: nil)
                            accountsManager.add(account: account)
                            logger.debug("Starting navigation to LoginView with instance: \(instance)")
                            instanceViewModel.instanceAddress = searchText
                            showLoginView = true
                        } label: {
                            InstanceRowView(
                                instance: .mastodon(
                                    instance, host: searchText,
                                    isCompatible: true))
                        }
                    } else {
                        Button {
                            instanceViewModel.showIncompatibleInstanceAlert()
                        } label: {
                            InstanceRowView(
                                instance: .mastodon(
                                    instance, host: searchText,
                                    isCompatible: false))
                        }
                        .foregroundColor(.primary)
                    }
                }
                .listSectionSeparator(.hidden, edges: .top)
            }

            Section {
                ForEach(
                    filteredInstances.isEmpty
                        ? instances : filteredInstances, id: \.host
                ) { instance in
                    Button {
                        let account = AppAccount(instance: instance.host, oauthToken: nil)
                        accountsManager.add(account: account)
                        logger.debug("Starting navigation to LoginView with instance: \(instance)")
                        instanceViewModel.instanceAddress = instance.host
                        showLoginView = true
                    } label: {
                        InstanceRowView(instance: .app(instance))
                    }
                }
            }
            .listSectionSeparator(.hidden, edges: .top)

            if instanceViewModel.error != nil {
                Section {
                    HStack {
                        Spacer()
                        Text(
                            String(
                                localized: "instance_search_empty",
                                table: "Settings")
                        )
                        .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .listSectionSeparator(.hidden, edges: .bottom)
            }
        }
        .navigationTitle(
            String(localized: "instance_title", table: "Settings")
        )
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.plain)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(
                localized: "instance_search_prompt", table: "Settings")
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onChange(of: searchText) { newValue in
            instanceViewModel.updateSearchText(newValue)
        }
        .task {
            logger.debug(
                "InstanceView initialized with isAddingAccount: \(isAddingAccount)"
            )
        }
        .navigationDestination(isPresented: $showLoginView) {
            LoginView(instanceAddress: instanceViewModel.instanceAddress, isAddingAccount: isAddingAccount)
        }
        .sheet(isPresented: $instanceViewModel.showIncompatibleAlert) {
                VStack(spacing: 0) {
                    HStack {
                        Text(
                            String(
                                localized: "instance_alert_title",
                                table: "Settings")
                        )
                        .font(.headline)
                        Spacer()
                        Button(action: {
                            instanceViewModel.showIncompatibleAlert = false
                        }) {
                            Image(systemSymbol: .xmarkCircleFill)
                                .font(.title2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()

                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemSymbol: .exclamationmarkTriangleFill)
                            .font(.largeTitle)

                        VStack(spacing: 12) {
                            Text(
                                String(
                                    format: String(
                                        localized:
                                            "instance_alert_incompatible",
                                        table: "Settings"), searchText)
                            )
                            .font(.body)
                            .multilineTextAlignment(.center)

                            Text(
                                String(
                                    localized: "instance_alert_description",
                                    table: "Settings")
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, -40)
                    .padding(.horizontal)

                    Spacer()
            }
                .background(.ultraThinMaterial)
            .presentationDetents([.fraction(0.45)])
            .presentationDragIndicator(.visible)
        }
        .toolbar {
            if isAddingAccount {
                ToolbarItem(placement: .topBarLeading) {
                    Text("instance_title", tableName: "Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                }
                ToolbarItem(placement: .principal) {
                    Text("instance_title", tableName: "Settings")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 2)
                        .hidden()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.headline)
                    }
                }
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

// 抽取实例行视图为单独的组件
private struct InstanceRowView: View {
    enum InstanceType {
        case mastodon(MastodonInstance, host: String, isCompatible: Bool)
        case app(AppInstance)

        var title: String {
            switch self {
            case .mastodon(let instance, _, _): return instance.title
            case .app(let instance): return instance.name
            }
        }

        var host: String {
            switch self {
            case .mastodon(_, let host, _): return host
            case .app(let instance): return instance.host
            }
        }

        var description: String {
            switch self {
            case .mastodon(let instance, _, _): return instance.shortDescription
            case .app(let instance): return instance.description
            }
        }

        var userCount: String {
            switch self {
            case .mastodon(let instance, _, _):
                return "\(instance.stats.userCount)"
            case .app(let instance): return instance.users
            }
        }

        var tags: [String] {
            switch self {
            case .mastodon(let instance, _, _): return instance.languages ?? []
            case .app(let instance): return instance.tags
            }
        }

        var secondaryIconType: IconType {
            switch self {
            case .mastodon: return .globe
            case .app: return .tag
            }
        }

        var iconURL: URL? {
            switch self {
            case .mastodon(let instance, _, _): return instance.thumbnail
            case .app: return nil
            }
        }

        var iconName: String? {
            switch self {
            case .mastodon: return nil
            case .app(let instance): return instance.iconName
            }
        }

        var isCompatible: Bool {
            switch self {
            case .mastodon(_, _, let isCompatible): return isCompatible
            case .app: return true
            }
        }
    }

    let instance: InstanceType

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let url = instance.iconURL {
                    KFImage(url)
                        .placeholder {
                            Image(systemSymbol: .serverRack)
                                .foregroundColor(.secondary)
                        }
                        .resizable()
                        .scaledToFill()
                } else if let iconName = instance.iconName {
                    Image(iconName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemSymbol: .serverRack)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(instance.title)
                        .font(.headline)
                    Text(instance.host)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !instance.isCompatible {
                        Spacer()
                        Image(systemSymbol: .exclamationmarkTriangleFill)
                            .foregroundColor(.orange)
                    }
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemSymbol: .personFill)
                            .foregroundColor(.secondary)
                        Text(instance.userCount)
                    }

                    if !instance.tags.isEmpty {
                        HStack(spacing: 4) {
                            Image(
                                systemName: instance.secondaryIconType
                                    .systemName
                            )
                            .foregroundColor(.secondary)
                            Text(instance.tags.joined(separator: ", "))
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text(instance.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
