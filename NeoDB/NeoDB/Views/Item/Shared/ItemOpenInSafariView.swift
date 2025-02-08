//
//  ItemOpenInSafariView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/8/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct ItemOpenInSafariView: View {
    let item: any ItemProtocol
    var accountsManager: AppAccountsManager? = nil

    @Environment(\.openURL) private var openURL

    var shareURL: URL? {
        return URL(string: item.id)
    }

    var body: some View {
        Group {
            if let shareURL = shareURL {
                Button(
                    String(
                        format: String(
                            localized: "item_open_in_website",
                            table: "Item"),
                        accountsManager?.currentAccount.instance ?? "Safari"),
                    systemSymbol: .arrowUpRight
                ) {
                    openURL(shareURL)
                }

                Divider()
            }

            if let externalResources = item.externalResources {
                ForEach(externalResources, id: \.url) { resource in
                    Button(role: .none) {
                        openURL(resource.url)
                    } label: {
                        Label(resource.name, systemImage: resource.icon)
                    }
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
}
