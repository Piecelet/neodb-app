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

    enum PlusType {
        case monthly
        case yearly
        case lifetime
    }
    
    // 获取当前订阅类型
    var currentSubscriptionType: PlusType? {
        guard let entitlement = customerInfo?.entitlements.active[StoreConfig.RevenueCat.plus.entitlementName] else {
            return nil
        }
        
        switch entitlement.productIdentifier {
        case _ where entitlement.productIdentifier.contains("monthly"):
            return .monthly
        case _ where entitlement.productIdentifier.contains("yearly"):
            return .yearly
        case _ where entitlement.productIdentifier.contains("lifetime"):
            return .lifetime
        default:
            return nil
        }
    }
    
    // 获取当前订阅的价格信息
    var subscriptionPrices: [String: String] {
        var prices: [String: String] = [:]
        
        plusOffering?.availablePackages.forEach { package in
            switch package.packageType {
            case .monthly:
                prices["monthly"] = package.storeProduct.localizedPriceString
            case .annual:
                prices["yearly"] = package.storeProduct.localizedPriceString
            case .lifetime:
                prices["lifetime"] = package.storeProduct.localizedPriceString
            default:
                break
            }
        }
        
        return prices
    }
    
    // 获取美元数值的价格信息
    var subscriptionPricesInUSDollar: [String: Decimal] {
        var prices: [String: Decimal] = [:]
        
        plusOffering?.availablePackages.forEach { package in
            switch package.packageType {
            case .monthly:
                prices["monthly"] = package.storeProduct.price
            case .annual:
                prices["yearly"] = package.storeProduct.price
            case .lifetime:
                prices["lifetime"] = package.storeProduct.price
            default:
                break
            }
        }
        
        return prices
    }
    
    // 获取当前订阅的过期时间
    var subscriptionExpirationDate: Date? {
        customerInfo?.entitlements.active[StoreConfig.RevenueCat.plus.entitlementName]?.expirationDate
    }

    init() {
        configure()
        // 可以在这里主动获取一次 customerInfo 以保证初始状态同步
        Task {
            await setCustomerInfo()
        }
    }

    private func configure() {
        Purchases.logLevel = AppConfig.isDebug == true ? .debug : .error
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
