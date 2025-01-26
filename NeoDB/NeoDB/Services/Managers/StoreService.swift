//
//  StoreService.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation
import RevenueCat

@MainActor
class StoreManager: ObservableObject {
    @Published var appUserID: String? = nil
    @Published var customerInfo: RevenueCat.CustomerInfo? = nil
    @Published var plusOffering: Offering? = nil

    var isPlus: Bool {
        return customerInfo?.entitlements.active[
            StoreConfig.RevenueCat.plus.entitlementName] != nil
    }

    init() {
        configure()
    }

    private func configure() {
        Purchases.logLevel = .error
        Purchases.proxyURL = StoreConfig.RevenueCat.proxyURL
        Purchases.configure(
            with:
                Configuration
                .builder(withAPIKey: StoreConfig.RevenueCat.apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
        setCustomerInfo()
    }

    func setCustomerInfo() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                self.customerInfo = customerInfo
                self.appUserID = Purchases.shared.appUserID
            } catch {
                print("Error setting customer info: \(error)")
            }
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

    func loadOfferings(refresh: Bool = false) async {
        do {
            if plusOffering == nil || refresh {
                let offerings = try await Purchases.shared.offerings()
                plusOffering = offerings.offering(identifier: "plus") ?? offerings.current
            }
        } catch {
            print("Error loading offerings: \(error)")
        }
    }

    func purchase(_ package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        await MainActor.run {
            self.customerInfo = result.customerInfo
        }
        return result.customerInfo
    }

    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        await MainActor.run {
            self.customerInfo = info
        }
        return info
    }
}
