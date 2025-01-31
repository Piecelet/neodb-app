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
    @State private var selectedInstance: String = ""
    @AppStorage(\.customInstance) private var customInstance: String
    
    private let instances = [
        (
            name: "NeoDB", host: "neodb.social",
            description: "一个自由、开放、互联的书籍、电影、音乐和游戏收藏评论交流社区。", tags: ["中文"]
        ),
        (
            name: "Eggplant", host: "eggplant.place",
            description: "reviews about book, film, music, podcast and game.",
            tags: ["English", "Beta"]
        ),
        (
            name: "ReviewDB", host: "reviewdb.app",
            description: "reviews about book, film, music, podcast and game.",
            tags: ["International"]
        ),
        (
            name: "Minreol", host: "minreol.dk",
            description:
                "MinReol er et dansk fællesskab centreret om bøger, film, TV-serier, spil og podcasts.",
            tags: ["German"]
        ),
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(instances, id: \.host) { instance in
                    NavigationLink {
                        LoginView()
                            .onAppear {
                                viewModel.updateInstance(instance.host)
                            }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(instance.name)
                                    .font(.body)
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
                    }
                }
            } header: {
                Text(String(localized: "instance_choose_title", table: "Settings"))
            }

            Section {
                TextField("instance.social", text: $customInstance)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .onSubmit {
                        if !customInstance.isEmpty {
                            viewModel.updateInstance(customInstance)
                        }
                    }
                
                if !customInstance.isEmpty {
                    NavigationLink {
                        LoginView()
                            .onAppear {
                                viewModel.updateInstance(customInstance)
                            }
                    } label: {
                        Text(String(localized: "login_button_continue", table: "Settings"))
                    }
                }
            } header: {
                Text(String(localized: "instance_custom_title", table: "Settings"))
            } footer: {
                Text(String(localized: "instance_custom_description", table: "Settings"))
            }
        }
        .navigationTitle(String(localized: "instance_select_title", table: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .task {
            viewModel.accountsManager = accountsManager
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

