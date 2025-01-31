//
//  PackageListView.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import RevenueCat
import SwiftUI

// PackageListView - 新的套餐列表视图
private struct PackageListView: View {
    let offering: Offering
    @Binding var showAllPlans: Bool
    @Binding var selectedPackage: Package?
    let viewModel: PurchaseViewModel
    
    var body: some View {
        VStack {
            Button {
                // 加快动画速度
                withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
                    HapticFeedback.selection()
                    showAllPlans.toggle()
                }
            } label: {
                HStack {
                    Text(
                        showAllPlans
                            ? String(
                                localized: "store_plans_hide",
                                table: "Settings")
                            : String(
                                localized: "store_plans_show",
                                table: "Settings")
                    )
                    .font(.headline)
                    Image(
                        systemName: showAllPlans
                            ? "chevron.down" : "chevron.up")
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )
                .padding(.horizontal)
            }
            .foregroundStyle(.primary)

            if showAllPlans {
                VStack(spacing: 8) {
                    ForEach(
                        offering.availablePackages.sorted {
                            $0.storeProduct.price
                                < $1.storeProduct.price
                        }, id: \.identifier
                    ) { package in
                        Button {
                            HapticFeedback.selection()
                            selectedPackage = package
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(
                                        (package.packageType
                                            == .lifetime
                                            ? String(
                                                localized:
                                                    "store_package_lifetime",
                                                table:
                                                    "Settings")
                                            : "\(package.packageType == .annual ? String(localized: "store_package_yearly", table: "Settings") : String(localized: "store_package_monthly_short", table: "Settings"))")
                                            + " • \(package.storeProduct.localizedPriceString)"
                                    ).font(.headline)

                                }
                                Spacer(minLength: 0)
                                // 如果是年订阅，展示节省多少
                                if package.packageType
                                    == .annual
                                {
                                    if let savings =
                                        viewModel
                                        .calculateSavings(
                                            for: package,
                                            in: offering)
                                    {
                                        Text(
                                            String(
                                                format: String(
                                                    localized:
                                                        "store_badge_save",
                                                    table:
                                                        "Settings"
                                                ),
                                                String(savings)
                                            )
                                        )
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Color.accentColor
                                        )
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .buttonStyle(.plain)
                        .padding()
                        .background(
                            selectedPackage?.identifier
                                == package.identifier
                                ? Color.gray.opacity(0.2)
                                : .clear
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top)
            }
        }
        .padding(.horizontal)
    }
}
