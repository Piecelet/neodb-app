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
    var router: Router? = nil
    var storeManager: StoreManager? = nil

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
            if let scheme = resource.makeAppScheme(), resource.type == .douban {
                return (resource: resource, scheme: scheme)
            }
            return nil
        } ?? []
    }

    private var searchAppScheme:
        [(resource: ItemExternalResourceSchema, scheme: URL)]
    {
        return item.externalResources?.compactMap { resource in
            if let scheme = resource.makeAppSearchScheme(
                query: item.title ?? ""), resource.type == .douban
            {
                return (resource: resource, scheme: scheme)
            }
            return nil
        } ?? []
    }

    var body: some View {
        Group {
            if let shareURL = shareURL {
                Section {
                    Link(
                        destination: shareURL
                    ) {
                        Label(
                            String(
                                format: String(
                                    localized: "item_open_in_website",
                                    table: "Item"),
                                accountsManager?.currentAccount.instance
                                    ?? "Safari"
                            ),
                            systemSymbol: .safari
                        )
                        .labelStyle(.iconOnly)
                    }
                }
            }
            if !appSchemes.isEmpty {
                Section {
                    availableAppsView
                } header: {
                    Text(
                        "item_open_in_section_title_apps",
                        tableName: "Item")
                }
            }
            if let title = item.title, !title.isEmpty {
                Section {
                    searchAppView
                } header: {
                    Text(
                        "item_open_in_section_title_search",
                        tableName: "Item")
                }
            }
            if !websiteResources.isEmpty {
                Section {
                    availableWebsitesView
                } header: {
                    Text(
                        "item_open_in_section_title_websites",
                        tableName: "Item")
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
            Label(
                String(
                    localized: "item_open_in_open_links",
                    defaultValue: "Open Links", table: "Item"),
                symbol: .sfSymbol(.arrowUpForwardApp)
            )
            .labelStyle(.iconOnly)
        }
        .enableInjection()
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
        Link(destination: resource.url) {
            Label(resource.name, symbol: resource.symbolImage)
        }
    }

    var availableAppsView: some View {
        Group {
            if !appSchemes.isEmpty {
                ForEach(appSchemes, id: \.scheme.absoluteString) { pair in
                    Group {
                        if let storeManager = storeManager, storeManager.isPlus
                        {
                            Link(destination: pair.scheme) {
                                Label(
                                    pair.resource.name,
                                    symbol: pair.resource.symbolImage)
                            }
                        } else {
                            Button {
                                router?.presentSheet(
                                    .purchaseWithFeature(feature: .integration))
                            } label: {
                                Label(
                                    pair.resource.name,
                                    symbol: pair.resource.symbolImage)
                            }
                        }
                    }
                }
            }
        }
    }

    var searchAppView: some View {
        Group {
            ForEach(searchAppScheme, id: \.scheme.absoluteString) { pair in
                Group {
                    if let storeManager = storeManager, storeManager.isPlus {
                        Link(destination: pair.scheme) {
                            Label(
                                String(
                                    format: String(
                                        localized: "item_open_in_search_format",
                                        table: "Item"),
                                    pair.resource.name),
                                symbol: pair.resource.symbolImage)
                        }
                    } else {
                        Button {
                            router?.presentSheet(
                                .purchaseWithFeature(feature: .integration))
                        } label: {
                            Label(
                                pair.resource.name,
                                symbol: pair.resource.symbolImage)
                        }
                    }
                }
            }
        }
    }
}
