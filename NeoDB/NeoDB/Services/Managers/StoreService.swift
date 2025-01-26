//
//  StoreService.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import Foundation
import RevenueCat

enum StoreService {
    /// RevenueCat API Key
    private static let apiKey = StoreConfig.RevenueCat.apiKey
    
    /// 配置 RevenueCat SDK
    static func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(appUserID: nil)  // 让 RevenueCat 生成匿名用户 ID
                .build()
        )
    }
    
    /// 检查是否是订阅用户
    static func checkSubscriptionStatus() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            // 检查是否有活跃的订阅或者终身会员
            return customerInfo.entitlements.active.isEmpty == false
        } catch {
            print("Error checking subscription status: \(error)")
            return false
        }
    }
    
    /// 获取当前用户信息
    static func getCurrentCustomerInfo() async -> CustomerInfo? {
        do {
            return try await Purchases.shared.customerInfo()
        } catch {
            print("Error fetching customer info: \(error)")
            return nil
        }
    }
} 