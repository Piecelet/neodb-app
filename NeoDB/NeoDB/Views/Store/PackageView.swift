//
//  PackageView.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import RevenueCat

struct PackageView: View {
    let package: Package

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.headline)
                    if package.packageType == .lifetime {
                        Text(
                            String(
                                localized: "store_purchase_onetime",
                                table: "Settings")
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        Text(package.storeProduct.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.title3)
                        .fontWeight(.bold)

                    if package.packageType != .lifetime {
                        Text(
                            package.packageType == .annual
                                ? String(
                                    format: String(
                                        localized: "store_period_year",
                                        table: "Settings"),
                                    package.storeProduct.localizedPriceString)
                                : String(
                                    format: String(
                                        localized: "store_period_month",
                                        table: "Settings"),
                                    package.storeProduct.localizedPriceString)
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
