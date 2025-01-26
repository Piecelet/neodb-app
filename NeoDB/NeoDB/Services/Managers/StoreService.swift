//
//  StoreService.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation
import RevenueCat

class StoreManager: ObservableObject {
    @Published var appUserID: String? = nil
    @Published var customerInfo: RevenueCat.CustomerInfo? = nil
    @Published var plusOffering: Offering? = nil

    var isPlus: Bool {
        return customerInfo?.entitlements.active[StoreConfig.RevenueCat.plus.entitlementName] != nil
    }

    private var offerings: Offerings? = nil

    init() {
        configure()
    }

    /// 配置 RevenueCat SDK
    private func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(
            with: Configuration
                .builder(withAPIKey: StoreConfig.RevenueCat.apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
        Task {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            self.appUserID = Purchases.shared.appUserID
            offerings = try await Purchases.shared.offerings()
            self.plusOffering = offerings?.offering(identifier: StoreConfig.RevenueCat.plus.offeringIdentifier) ?? offerings?.current
        }
    }

    func getCurrentCustomerInfo() async -> CustomerInfo? {
        do {
            return try await Purchases.shared.customerInfo()
        } catch {
            print("Error fetching customer info: \(error)")
            return nil
        }
    }
    
}
