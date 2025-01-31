//
//  BottomPurchaseView.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import ButtonKit  // 引入 ButtonKit
import RevenueCat
import SwiftUI

struct BottomPurchaseView: View {
    private enum PackageText {
        case lifetime(price: String)
        case yearly(price: String)
        case monthly(price: String)
        case purchased(package: Package)

        var buttonText: String {
            switch self {
            case .lifetime:
                return String(
                    localized: "store_button_upgrade_forever", table: "Settings"
                )
            case .yearly:
                return String(
                    localized: "store_button_try_free", table: "Settings")
            case .monthly:
                return String(
                    localized: "store_button_upgrade_now", table: "Settings")
            case .purchased:
                return String(
                    localized: "store_button_thank_you", table: "Settings")
            }
        }

        var descriptionText: String {
            switch self {
            case .lifetime(let price):
                return String(
                    format: String(
                        localized: "store_package_lifetime_price",
                        table: "Settings"),
                    price
                )
            case .yearly(let price):
                return String(
                    format: String(
                        localized: "store_package_yearly_price",
                        table: "Settings"),
                    price
                )
            case .monthly(let price):
                return String(
                    format: String(
                        localized: "store_package_monthly_price",
                        table: "Settings"),
                    price
                )
            case .purchased(let package):
                switch package.packageType {
                case .lifetime:
                    return String(
                        localized: "store_package_lifetime", table: "Settings")
                case .annual:
                    return String(
                        localized: "store_package_annual", table: "Settings")
                case .monthly:
                    return String(
                        localized: "store_package_monthly", table: "Settings")
                default:
                    return String(
                        localized: "store_package_active", table: "Settings")
                }
            }
        }
    }

    let offering: Offering?
    @Binding var showAllPlans: Bool
    @Binding var selectedPackage: Package?
    let viewModel: PurchaseViewModel
    @EnvironmentObject private var storeManager: StoreManager

    private func getPackageText(for package: Package) -> PackageText {
        if storeManager.isPlus {
            return .purchased(package: package)
        }
        let price = package.storeProduct.localizedPriceString
        switch package.packageType {
        case .lifetime:
            return .lifetime(price: price)
        case .annual:
            return .yearly(price: price)
        case .monthly:
            return .monthly(price: price)
        default:
            return .monthly(price: price)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
            } else {
                if let offering {
                    if !storeManager.isPlus {
                        PackageListView(
                            offering: offering,
                            showAllPlans: $showAllPlans,
                            selectedPackage: $selectedPackage,
                            viewModel: viewModel
                        )
                    }

                    // 在这里使用 AsyncButton 触发购买操作，并指定 asyncButtonStyle
                    if let selectedPackage {
                        let packageText = getPackageText(for: selectedPackage)

                        VStack(spacing: 4) {
                            AsyncButton {
                                await viewModel.purchase(selectedPackage)
                            } label: {
                                Text(packageText.buttonText)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        storeManager.isPlus
                                            ? Color.gray : Color.accentColor
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12))
                            }
                            .asyncButtonStyle(.overlay)
                            .throwableButtonStyle(.none)
                            .disabledWhenLoading()
                            .disabled(storeManager.isPlus)
                            .padding(.horizontal)

                            Text(packageText.descriptionText)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}
