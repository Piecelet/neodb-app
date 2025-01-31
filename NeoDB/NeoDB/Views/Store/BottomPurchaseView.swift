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
            // 如果要在加载 Offerings（loadOfferings）时全局显示进度，可保留此视图判断
            // 但此处若只想让按钮自身在购买时显示加载动画，可酌情去掉对 viewModel.isLoading 的判断
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
            } else {
                if let offering {
                    if !storeManager.isPlus {
                        // 展示套餐列表切换，使用更快的动画
                        VStack {
                            Button {
                                // 加快动画速度
                                withAnimation(.easeInOut(duration: 0.2)) {
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
                                                Spacer()
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

                    // 在这里使用 AsyncButton 触发购买操作，并指定 asyncButtonStyle
                    if let selectedPackage {
                        let packageText = getPackageText(for: selectedPackage)

                        VStack(spacing: 4) {
                            AsyncButton {
                                // 使用 ButtonKit 的 async/throwable API，这里如果 purchase 抛出错误，会触发 ButtonKit 的默认动画
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
                            // 购买按钮在执行中会自动替换为进度动画
                            .asyncButtonStyle(.overlay)  // 在按钮本身覆盖显示加载动画
                            .throwableButtonStyle(.none)  // 不需要抛错时摇晃
                            .disabledWhenLoading()  // 加载时禁用二次点击
                            .disabled(storeManager.isPlus)  // 若已是Plus则禁用
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
