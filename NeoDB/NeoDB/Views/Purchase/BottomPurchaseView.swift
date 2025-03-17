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
            return .yearly(price: price, isTrialEligible: viewModel.isTrialEligible)
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
