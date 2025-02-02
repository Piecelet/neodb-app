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
        // 可以在这里主动获取一次 customerInfo 以保证初始状态同步
        Task {
            await setCustomerInfo()
        }
    }

    private func configure() {
        Purchases.logLevel = .error
        Purchases.proxyURL = StoreConfig.RevenueCat.proxyURL
        // 使用带有 StoreKit 2 的最现代化方式
        Purchases.configure(
            with: Configuration
                .builder(withAPIKey: StoreConfig.RevenueCat.apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
    }

    func setCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.appUserID = Purchases.shared.appUserID
        } catch {
            print("Error setting customer info: \(error)")
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
        // RevenueCat 提供的最简洁的 async/await 购买接口
        let result = try await Purchases.shared.purchase(package: package)
        // 购买后将最新的 customerInfo 写回本地
        self.customerInfo = result.customerInfo
        return result.customerInfo
    }

    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        self.customerInfo = info
        return info
    }
}
