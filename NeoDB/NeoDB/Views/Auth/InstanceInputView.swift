//
//  InstanceInputView.swift
//  NeoDB
//
//  Created by citron on 1/23/25.
//

import SwiftUI

struct InstanceInputView: View {
    @State private var selectedInstance: String
    @AppStorage(\.customInstance) private var customInstance: String
    @Environment(\.dismiss) private var dismiss

    let onSubmit: (String) -> Void

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

    init(selectedInstance: String, onSubmit: @escaping (String) -> Void) {
        _selectedInstance = State(initialValue: selectedInstance)
        self.onSubmit = onSubmit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            HStack {
                Text(String(localized: "instance_select_title", table: "Settings"))
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
                                        ForEach(instance.tags, id: \.self) {
                                            tag in
                                            Text(tag)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Color.secondary.opacity(0.1)
                                                )
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
                    Text(String(localized: "instance_choose_title", table: "Settings"))
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
                                if selectedInstance == customInstance
                                    && !customInstance.isEmpty
                                {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .padding(.trailing, 8)
                                }
                            }
                        )
                } header: {
                    Text(String(localized: "instance_custom_title", table: "Settings"))
                } footer: {
                    Text(String(localized: "instance_custom_description", table: "Settings"))
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
