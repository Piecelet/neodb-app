//
//  MarkDataControllerProvider.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/31/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import Perception

// MARK: - Protocol
@MainActor
protocol MarkDataControlling {
    var shelfType: ShelfType { get set }
    var visibility: MarkVisibility { get set }
    var commentText: String? { get set }
    var ratingGrade: Int? { get set }
    var tags: [String] { get set }
    
    func updateMark() async throws
    func deleteMark() async throws
}

// MARK: - Provider
@MainActor
final class MarkDataControllerProvider {
    static let shared = MarkDataControllerProvider()
    private let cacheService = CacheService()
    
    // 内存缓存，用于快速访问
    private var controllers: [String: MarkDataController] = [:]
    
    func dataController(for mark: MarkSchema, accountsManager: AppAccountsManager) -> MarkDataController {
        if let controller = controllers[mark.id] {
            return controller
        }
        let controller = MarkDataController(mark: mark, accountsManager: accountsManager, cacheService: cacheService)
        controllers[mark.id] = controller
        return controller
    }
    
    func updateDataControllers(for marks: [MarkSchema], accountsManager: AppAccountsManager) {
        for mark in marks {
            let controller = dataController(for: mark, accountsManager: accountsManager)
            controller.updateFrom(mark: mark)
        }
    }
    
    func removeController(for markId: String) {
        controllers.removeValue(forKey: markId)
    }
}

// MARK: - Controller
@Perceptible
final class MarkDataController: MarkDataControlling {
    private let mark: MarkSchema
    private let accountsManager: AppAccountsManager
    private let cacheService: CacheService
    
    var shelfType: ShelfType
    var visibility: MarkVisibility
    var commentText: String?
    var ratingGrade: Int?
    var tags: [String]
    var postToFediverse: Bool = true
    var createdTime: Date = Date()
    var changeTime: Bool = false
    
    init(mark: MarkSchema, accountsManager: AppAccountsManager, cacheService: CacheService) {
        self.mark = mark
        self.accountsManager = accountsManager
        self.cacheService = cacheService
        
        self.shelfType = mark.shelfType
        self.visibility = mark.visibility
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.tags = mark.tags
        if let date = mark.createdTime.asDate {
            self.createdTime = date
        }
    }
    
    func updateFrom(mark: MarkSchema) {
        self.shelfType = mark.shelfType
        self.visibility = mark.visibility
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.tags = mark.tags
        if let date = mark.createdTime.asDate {
            self.createdTime = date
        }
    }
    
    func updateMark() async throws {
        // 保存旧值用于回滚
        let oldValues = (shelfType, visibility, commentText, ratingGrade, tags)
        
        do {
            let markIn = MarkInSchema(
                shelfType: shelfType,
                visibility: visibility,
                commentText: commentText?.isEmpty == false ? commentText : nil,
                ratingGrade: ratingGrade == 0 ? nil : ratingGrade,
                tags: tags,
                createdTime: changeTime ? ServerDate.from(createdTime) : nil,
                postToFediverse: postToFediverse
            )
            
            let endpoint = MarkEndpoint.mark(itemId: mark.item.uuid, mark: markIn)
            _ = try await accountsManager.currentClient.fetch(endpoint, type: MessageSchema.self)
            
            // 更新缓存
            // 注意：需要获取新的mark数据来更新缓存，因为服务器可能会修改一些字段
            let getEndpoint = MarkEndpoint.get(itemId: mark.item.uuid)
            let updatedMark = try await accountsManager.currentClient.fetch(getEndpoint, type: MarkSchema.self)
            
            try await cacheService.cacheMark(
                updatedMark,
                key: accountsManager.currentAccount.id,
                itemUUID: mark.item.uuid,
                instance: accountsManager.currentAccount.instance
            )
            
            // 更新控制器状态
            updateFrom(mark: updatedMark)
            
        } catch {
            // 错误回滚
            (shelfType, visibility, commentText, ratingGrade, tags) = oldValues
            throw error
        }
    }
    
    func deleteMark() async throws {
        let endpoint = MarkEndpoint.delete(itemId: mark.item.uuid)
        _ = try await accountsManager.currentClient.fetch(endpoint, type: MessageSchema.self)
        
        // 删除缓存
        try await cacheService.removeMark(
            key: accountsManager.currentAccount.id,
            itemUUID: mark.item.uuid
        )
        
        // 从provider中移除controller
        MarkDataControllerProvider.shared.removeController(for: mark.id)
    }
}
