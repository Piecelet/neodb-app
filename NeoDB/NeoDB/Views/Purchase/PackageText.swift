//
//  PackageText.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 3/17/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import RevenueCat

enum PackageText {
    case lifetime(price: String)
    case yearly(price: String, isTrialEligible: Bool = false)
    case monthly(price: String)
    case purchased(package: Package)

    var buttonText: String {
        switch self {
        case .lifetime:
            return String(
                localized: "store_button_upgrade_forever",
                defaultValue: "Upgrade Forever", table: "Settings"
            )
        case .yearly(_, let isTrialEligible):
            return isTrialEligible
                ? String(
                    localized: "store_button_try_free",
                    defaultValue: "Try Free for 7 Days", table: "Settings")
                : String(
                    localized: "store_button_upgrade_now",
                    defaultValue: "Upgrade Now", table: "Settings"
                )
        case .monthly:
            return String(
                localized: "store_button_upgrade_now",
                defaultValue: "Upgrade Now", table: "Settings"
            )
        case .purchased:
            return String(
                localized: "store_button_thank_you",
                defaultValue: "Thank you", table: "Settings")
        }
    }

    var descriptionText: String {
        switch self {
        case .lifetime(let price):
            return String(
                format: String(
                    localized: "store_package_lifetime_price_description",
                    defaultValue: "%@ once · Lifetime access",
                    table: "Settings"),
                price
            )
        case .yearly(let price, let isTrialEligible):
            return isTrialEligible
                ? String(
                    format: String(
                        localized:
                            "store_package_yearly_price_with_trial_description",
                        defaultValue: "Then %@ per year · Cancel anytime",
                        table: "Settings"),
                    price
                )
                : String(
                    format: String(
                        localized: "store_package_yearly_price_description",
                        defaultValue: "%@ per year · Cancel anytime",
                        table: "Settings"),
                    price
                )
        case .monthly(let price):
            return String(
                format: String(
                    localized: "store_package_monthly_price_description",
                    defaultValue: "%@ per month · Cancel anytime",
                    table: "Settings"),
                price
            )
        case .purchased(let package):
            switch package.packageType {
            case .lifetime:
                return String(
                    localized: "store_package_purchased_lifetime_description",
                    defaultValue: "Lifetime Access", table: "Settings")
            case .annual:
                return String(
                    localized: "store_package_purchased_yearly_description",
                    defaultValue: "Yearly Subscription", table: "Settings")
            case .monthly:
                return String(
                    localized: "store_package_purchased_monthly_description",
                    defaultValue: "Monthly Subscription", table: "Settings")
            default:
                return String(
                    localized: "store_package_purchased_active_description",
                    defaultValue: "Active Access", table: "Settings")
            }
        }
    }

    var listText: String {
        switch self {
        case .lifetime:
            return String(
                localized: "store_package_list_lifetime_label",
                defaultValue: "Lifetime",
                table: "Settings")
        case .yearly:
            return String(
                localized: "store_package_list_yearly_label",
                defaultValue: "Yearly",
                table: "Settings")
        case .monthly:
            return String(
                localized: "store_package_list_monthly_label",
                defaultValue: "Monthly",
                table: "Settings")
        case .purchased:
            return ""
        }
    }
}

extension PackageText {
    static func getText(package: Package, isTrialEligible: Bool = false)
        -> PackageText?
    {
        switch package.packageType {
        case .lifetime:
            return .lifetime(price: package.storeProduct.localizedPriceString)
        case .annual:
            return .yearly(
                price: package.storeProduct.localizedPriceString,
                isTrialEligible: isTrialEligible)
        case .monthly:
            return .monthly(price: package.storeProduct.localizedPriceString)
        default:
            return nil
        }
    }
}
