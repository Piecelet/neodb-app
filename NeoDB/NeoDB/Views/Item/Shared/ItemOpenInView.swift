//
//  ItemOpenInView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ItemOpenInView: View {
    let item: any ItemProtocol
    var accountsManager: AppAccountsManager? = nil

    @Environment(\.openURL) private var openURL

    private var shareURL: URL? {
        return URL(string: item.id)
    }

    private var websiteResources: [ItemExternalResourceSchema] {
        return item.externalResources ?? []
    }

    private var appSchemes:
        [(resource: ItemExternalResourceSchema, scheme: URL)]
    {
        return item.externalResources?.compactMap { resource in
            if let scheme = resource.makeAppScheme() {
                return (resource: resource, scheme: scheme)
            }
            return nil
        } ?? []
    }

    var body: some View {
        Group {
            if let shareURL = shareURL {
                Section {
                    Button(
                        String(
                            format: String(
                                localized: "item_open_in_website",
                                table: "Item"),
                            accountsManager?.currentAccount.instance ?? "Safari"
                        ),
                        systemSymbol: .arrowUpRight
                    ) {
                        openURL(shareURL)
                    }
                }
            }
            if !appSchemes.isEmpty {
                Section {
                    availableAppsView
                } header: {
                    Text("Open in App")
                }
                if !websiteResources.isEmpty {
                    Menu {
                        availableWebsitesView
                    } label: {
                        Label("Open in Website", systemSymbol: .safari)
                            .labelStyle(.iconOnly)
                    }
                }
            } else if !websiteResources.isEmpty {
                Section {
                    availableWebsitesView
                } header: {
                    Text("Open in Website")
                }
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    var bodyMenu: some View {
        Menu {
            self.body
        } label: {
            Label("Open website", systemSymbol: .safari)
                .labelStyle(.iconOnly)
        }
    }

    var availableWebsitesView: some View {
        Group {
            if let externalResources = item.externalResources {
                ForEach(externalResources, id: \.url) { resource in
                    websiteView(resource)
                }
            }
        }
    }

    func websiteView(_ resource: ItemExternalResourceSchema) -> some View {
        Button(role: .none) {
            openURL(resource.url)
        } label: {
            Label(resource.name, systemImage: resource.icon)
        }
    }

    var availableAppsView: some View {
        Group {
            if !appSchemes.isEmpty {
                ForEach(appSchemes, id: \.scheme.absoluteString) { pair in
                    Button {
                        openURL(pair.scheme)
                    } label: {
                        Label(
                            pair.resource.name, systemImage: pair.resource.icon)
                    }
                }
            }
        }
    }
}
