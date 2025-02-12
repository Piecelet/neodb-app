import Foundation

enum AppConfig {
    static let baseURL = "https://neodb.social"
    
    static let defaultInstance = "neodb.social"
    
    static let defaultItemCoverRatio: CGFloat = 3 / 4
    
    static let wishkitApiKey = "6AA7DB14-8EED-4895-B4D6-3F6EB5210921"

    static let telemetryDeckAppID = "08C5A003-C174-4FAE-ADA2-A9BA3A008FF7"

    static let appStoreId = "6739444863"

    #if DEBUG
        static let isDebug = true
    #else
        static let isDebug = false
    #endif
    
    enum OAuth {
        static let redirectUri = "neodb://oauth/callback"
        static let scopes = "read write follow push"
        static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Mobile/15E148 Safari/604.1"
    }
    
    enum Trakt {
        static let redirectUri = "piecelet://oauth/trakt/callback"
    }
    
    enum InstanceSocial {
        static let token = "0psygl3dJMy3JKHG3wmzjFvORbN7DAqb7E0CLwKckZ8tGOnvU5t4QA5MhJnOICU0hgUb2BbngwhDwlXY3boEXLbTN1K7Ppuku5bRStnZOSJcwGc5JhgfVWJ8LiyOUBN1"
    }
    
    enum PublicInfo {
        static let name = "Piecelet for NeoDB"
        static let website = "https://github.com/lcandy2/neodb-app"
    }

    static let instances: [AppInstance] = [
        AppInstance(name: "NeoDB", iconName: "appInstance.neodb", host: "neodb.social", description: "一个自由、开放、互联的书籍、电影、音乐和游戏收藏评论交流社区。", tags: ["中文"], users: "19.7K"),
        AppInstance(name: "Eggplant", iconName: "appInstance.eggplant", host: "eggplant.place", description: "Reviews about book, film, music, podcast and game.", tags: ["English", "Beta"], users: "270"),
        AppInstance(name: "ReviewDB", iconName: nil, host: "reviewdb.app", description: "A community for book, film, music, podcast and game reviews.", tags: ["International"], users: "58"),
        AppInstance(name: "Minreol", iconName: "appInstance.minreol", host: "minreol.dk", description: "MinReol er et dansk fællesskab centreret om bøger, film, TV-serier, spil og podcasts.", tags: ["Danish"], users: "38"),
    ]
}
