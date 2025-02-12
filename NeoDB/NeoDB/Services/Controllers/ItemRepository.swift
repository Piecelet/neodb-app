//
//  ItemRepository.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/10/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import OSLog

@MainActor
class ItemRepository: ObservableObject {
    static let shared = ItemRepository()
    
    private let logger = Logger(subsystem: "com.neodb", category: "ItemRepository")
    // 内存缓存，用 item.id 作为键，保存已经加载过的 item（遵循 ItemProtocol 的实例）
    @Published var items: [String: any ItemProtocol] = [:]
    
    private let cacheService = CacheService.shared
    
    /// 加载 item 数据
    ///
    /// 当 refresh 为 false 时，首先检查内存缓存；若没有命中，再尝试从磁盘缓存中读取（通过 CacheService.retrieveItem）；如果仍然没有，且当前 item 不具备完整信息（例如 description 或 rating 为 nil），则通过网络接口加载完整数据。加载成功后，将数据写入内存缓存，并调用 CacheService.cacheItem 写入磁盘缓存。
    ///
    /// 参数 item 为初始的 item 占位对象，accountsManager 用于验证身份以及执行网络请求。
    ///
    /// 返回值为加载后的完整 item，若加载失败则返回 nil。
    func fetchItem(for item: any ItemProtocol, refresh: Bool = false, accountsManager: AppAccountsManager) async -> (any ItemProtocol)? {
        let key = item.id
        
        // 若不要求刷新，先从内存缓存中查找已存在的数据
        if !refresh, let cached = items[key] {
            logger.debug("Item \(item.uuid) found in in-memory cache")
            return cached
        }
        
        // 尝试从磁盘缓存中读取数据（仅在不刷新时执行）
        if !refresh {
            do {
                if let diskCached = try await cacheService.retrieveItem(id: item.id, category: item.category) {
                    logger.debug("Item \(item.uuid) retrieved from disk cache")
                    items[key] = diskCached
                    return diskCached
                }
            } catch {
                logger.error("Error retrieving item \(item.uuid) from disk cache: \(error.localizedDescription)")
            }
        }
        
        // 如果传入的 item 已经包含完整的详情（例如 description 与 rating 均不为 nil），则无需再次加载
        if item.description != nil && item.rating != nil {
            logger.debug("Item \(item.uuid) already has full details")
            items[key] = item
            return item
        }
        
        // 网络请求前检查身份验证状态
        guard accountsManager.isAuthenticated else {
            logger.error("Cannot fetch item \(item.uuid) because accountsManager is not authenticated")
            return nil
        }
        
        // 发起网络请求加载完整数据
        do {
            logger.debug("Fetching item \(item.uuid) from network")
            let endpoint = ItemEndpoint.make(id: item.uuid, category: item.category)
            let fetched = try await accountsManager.currentClient.fetch(endpoint, type: ItemSchema.makeType(category: item.category))
            logger.debug("Successfully fetched item \(item.uuid) from network")
            // 更新内存缓存
            items[key] = fetched
            // 将加载到的数据写入磁盘缓存
            try? await cacheService.cacheItem(fetched, id: item.id, category: item.category)
            return fetched
        } catch {
            logger.error("Failed to fetch item \(item.uuid): \(error.localizedDescription)")
            return nil
        }
    }
}
