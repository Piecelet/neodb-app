import Foundation

extension Notification.Name {
    // 账号相关
    static let accountSwitched = Notification.Name("accountSwitched")
    static let accountAdded = Notification.Name("accountAdded")
    static let accountRemoved = Notification.Name("accountRemoved")
    
    // 缓存相关
    static let cachesCleared = Notification.Name("cachesCleared")
}

struct NotificationKeys {
    static let accountId = "accountId"
    static let instance = "instance"
    static let error = "error"
}

extension NotificationCenter {
    static func postAccountSwitched(_ account: AppAccount) {
        NotificationCenter.default.post(
            name: .accountSwitched,
            object: nil,
            userInfo: [
                NotificationKeys.accountId: account.id,
                NotificationKeys.instance: account.instance
            ]
        )
    }
    
    static func postAccountAdded(_ account: AppAccount) {
        NotificationCenter.default.post(
            name: .accountAdded,
            object: nil,
            userInfo: [
                NotificationKeys.accountId: account.id,
                NotificationKeys.instance: account.instance
            ]
        )
    }
    
    static func postAccountRemoved(_ account: AppAccount) {
        NotificationCenter.default.post(
            name: .accountRemoved,
            object: nil,
            userInfo: [
                NotificationKeys.accountId: account.id,
                NotificationKeys.instance: account.instance
            ]
        )
    }
    
    static func postCachesCleared() {
        NotificationCenter.default.post(name: .cachesCleared, object: nil)
    }
} 