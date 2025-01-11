# Logging System Design

## Overview

NeoDB 使用 Apple 推薦的 OSLog 框架實現統一的日誌系統，提供結構化的日誌記錄功能。日誌系統位於 `Shared/Logging` 目錄下，遵循項目的架構標準。

## 設計思路

### 1. 分類管理

根據功能模塊劃分日誌類別：

```swift
Logger.lifecycle  // 應用生命週期
Logger.network    // 網絡請求和響應
Logger.data       // 數據持久化和緩存
Logger.auth       // 用戶認證
Logger.view       // 視圖生命週期
Logger.userAction // 用戶交互
Logger.performance // 性能指標
```

### 2. 日誌級別

每個類別支持不同的日誌級別：

- `debug`: 調試信息，僅在開發環境使用
- `info`: 一般信息，可用於記錄正常流程
- `warning`: 警告信息，表示潛在問題
- `error`: 錯誤信息，表示操作失敗
- `fault`: 嚴重錯誤，影響系統運行

### 3. 日誌格式

統一的日誌格式包含：

```
[文件名:行號] 函數名 - 具體消息
```

例如：
```
[ItemDetailViewModel.swift:42] loadItem(id:category:) - Loading item: 5gpdPcSMii0LTjFu0WLSay of category: movie
```

## 使用指南

### 1. 基本用法

```swift
// 視圖相關
Logger.view.info("View appeared")

// 網絡請求
Logger.network.debug("Starting API request to /items")

// 錯誤處理
Logger.error("Failed to load data: \(error.localizedDescription)")

// 用戶操作
Logger.userAction.info("User tapped login button")
```

### 2. 私有日誌實例

在視圖模型中使用私有日誌實例：

```swift
class ItemDetailViewModel: ObservableObject {
    private let logger = Logger.view
    
    func loadItem(id: String) {
        logger.debug("Loading item: \(id)")
        // ...
    }
}
```

### 3. 性能日誌

記錄性能相關的指標：

```swift
Logger.performance.debug("Image loading took \(duration)s")
```

## Console.app 使用技巧

### 1. 過濾器設置

在 Console.app 中設置以下過濾器：

- Subsystem: `app.neodb`
- Category: 選擇特定類別（如 `network`、`view` 等）
- Level: 選擇日誌級別

### 2. 保存搜索模式

創建常用的搜索模式：

1. 網絡請求監控：
   - Category: network
   - Level: Any

2. 錯誤追蹤：
   - Level: Error
   - Category: Any

3. 用戶行為分析：
   - Category: userAction
   - Level: Info

## 最佳實踐

1. **選擇合適的日誌級別**
   - `debug`: 用於開發調試
   - `info`: 用於重要流程節點
   - `warning`: 用於潛在問題
   - `error`: 用於實際錯誤

2. **包含上下文信息**
   ```swift
   logger.debug("Loading item: \(id) for user: \(userId)")
   ```

3. **避免敏感信息**
   ```swift
   // 正確做法：使用 privacy 參數
   logger.info("User \(username, privacy: .private) logged in")
   ```

4. **性能考慮**
   - 在 release 版本中自動禁用 debug 級別日誌
   - 使用條件編譯控制日誌輸出
   ```swift
   #if DEBUG
   logger.debug("Debug only message")
   #endif
   ```

## 參考資料

- [Explore logging in Swift (WWDC 2020)](https://developer.apple.com/videos/play/wwdc2020/10168/)
- [Unified logging and Activity Tracing (Apple Documentation)](https://developer.apple.com/documentation/os/logging)
- [Debug with structured logging (WWDC 2023)](https://developer.apple.com/videos/play/wwdc2023/10226/) 