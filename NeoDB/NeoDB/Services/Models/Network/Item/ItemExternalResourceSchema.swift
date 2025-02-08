//
//  ExternalResourceSchema.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

struct ItemExternalResourceSchema: Codable {
    let url: URL
}

enum ItemKnownExternalResource: String {
    case douban = "Douban"
    case goodreads = "Goodreads"
    case booksTW = "BooksTW"
    case googleBooks = "Google Books"
    case imdb = "IMDb"
    case tmdb = "TMDB"
    case bangumi = "Bangumi"
    case bandcamp = "Bandcamp"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case discogs = "Discogs"
    case applePodcasts = "Apple Podcast"
    case igdb = "IGDB"
    case steam = "Steam"
    case bgg = "BGG"
    case ao3 = "AO3"
    case jinjiang = "JinJiang"
    case qidian = "Qidian"
    case ypshuo = "Ypshuo"
    case bilibili = "Bilibili"
    case fedi = "Fediverse"
    case rss = "RSS"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        // Books
        case .douban: return "book.closed"
        case .goodreads: return "books.vertical"
        case .booksTW: return "book"
        case .googleBooks: return "book.circle"

        // Movies & TV
        case .imdb: return "film"
        case .tmdb: return "movieclapper"
        case .bangumi: return "tv"

        // Music
        case .bandcamp: return "music.note"
        case .spotify: return "music.note.list"
        case .appleMusic: return "music.note.house"
        case .discogs: return "record.circle"
        case .applePodcasts: return "waveform.circle"

        // Games
        case .igdb: return "gamecontroller"
        case .steam: return "gamecontroller.fill"
        case .bgg: return "dice"

        // Literature
        case .ao3: return "doc.text"
        case .jinjiang, .qidian, .ypshuo: return "text.book.closed"

        // Social & Others
        case .bilibili: return "play.tv"
        case .fedi: return "network"
        case .rss: return "dot.radiowaves.left.and.right"

        case .unknown: return "link"
        }
    }

    var host: String? {
        switch self {
        case .douban: return "douban.com"
        case .goodreads: return "goodreads.com"
        case .booksTW: return "books.com.tw"
        case .googleBooks: return "books.google.com"
        case .imdb: return "imdb.com"
        case .tmdb: return "themoviedb.org"
        case .bangumi: return "bangumi.tv"
        case .bandcamp: return "bandcamp.com"
        case .spotify: return "spotify.com"
        case .appleMusic: return "music.apple.com"
        case .discogs: return "discogs.com"
        case .applePodcasts: return "podcasts.apple.com"
        case .igdb: return "igdb.com"
        case .steam: return "steampowered.com"
        case .bgg: return "boardgamegeek.com"
        case .ao3: return "archiveofourown.org"
        case .jinjiang: return "jjwxc.net"
        case .qidian: return "qidian.com"
        case .ypshuo: return "ypshuo.com"
        case .bilibili: return "bilibili.com"
        case .fedi: return "fedi.com"
        case .rss: return "rss.com"
        case .unknown: return nil
        }
    }

    var scheme: String? {
        switch self {
        case .douban: return "douban://"
        case .goodreads: return "goodreads://"
        case .booksTW: return "books://"
        case .googleBooks: return "books://"
        case .imdb: return "imdb://"
        case .tmdb: return "themoviedb://"
        case .bangumi: return "bangumi://"
        case .bandcamp: return "bandcamp://"
        case .spotify: return "spotify://"
        case .appleMusic: return "music://"
        case .discogs: return "record://"
        case .applePodcasts: return "podcasts://"
        case .igdb: return "igdb://"
        case .steam: return "steam://"
        case .bgg: return "boardgamegeek://"
        case .ao3: return nil
        case .jinjiang: return "jjwxc.net"
        case .qidian: return "qidian.com"
        case .ypshuo: return "ypshuo.com"
        case .bilibili: return "bilibili.com"
        case .fedi: return "fedi.com"
        case .rss: return "rss://"
        case .unknown: return nil
        }
    }

    var displayName: String? {
        switch self {
        case .douban: return String(localized: "item_external_resource_douban", defaultValue: "豆瓣", table: "Item", comment: "Item External Resource Name - Douban")
        case .goodreads: return String(localized: "item_external_resource_goodreads", defaultValue: "Goodreads", table: "Item", comment: "Item External Resource Name - Goodreads")
        case .booksTW: return String(localized: "item_external_resource_bookstw", defaultValue: "博客來", table: "Item", comment: "Item External Resource Name - BooksTW")
        case .googleBooks: return String(localized: "item_external_resource_googlebooks", defaultValue: "Google Books", table: "Item", comment: "Item External Resource Name - Google Books")
        case .imdb: return String(localized: "item_external_resource_imdb", defaultValue: "IMDb", table: "Item", comment: "Item External Resource Name - IMDb")
        case .tmdb: return String(localized: "item_external_resource_tmdb", defaultValue: "TMDB", table: "Item", comment: "Item External Resource Name - TMDB")
        case .bangumi: return String(localized: "item_external_resource_bangumi", defaultValue: "Bangumi 番组计划", table: "Item", comment: "Item External Resource Name - Bangumi")
        case .bandcamp: return String(localized: "Bandcamp", defaultValue: "Bandcamp", table: "Item", comment: "Item External Resource Name - Bandcamp")
        case .spotify: return String(localized: "item_external_resource_spotify", defaultValue: "Spotify", table: "Item", comment: "Item External Resource Name - Spotify")
        case .appleMusic: return String(localized: "item_external_resource_applemusic", defaultValue: "Apple Music", table: "Item", comment: "Item External Resource Name - Apple Music")
        case .discogs: return String(localized: "item_external_resource_discogs", defaultValue: "Discogs", table: "Item", comment: "Item External Resource Name - Discogs")
        case .applePodcasts: return String(localized: "item_external_resource_applepodcasts", defaultValue: "Apple Podcasts", table: "Item", comment: "Item External Resource Name - Apple Podcasts")
        case .igdb: return String(localized: "item_external_resource_igdb", defaultValue: "IGDB", table: "Item", comment: "Item External Resource Name - IGDB")
        case .steam: return String(localized: "item_external_resource_steam", defaultValue: "Steam", table: "Item", comment: "Item External Resource Name - Steam")
        case .bgg: return String(localized: "item_external_resource_bgg", defaultValue: "Board Game Geek", table: "Item", comment: "Item External Resource Name - BGG")
        case .ao3: return String(localized: "item_external_resource_ao3", defaultValue: "AO3", table: "Item", comment: "Item External Resource Name - AO3")
        case .jinjiang: return String(localized: "item_external_resource_jinjiang", defaultValue: "晋江", table: "Item", comment: "Item External Resource Name - JinJiang")
        case .qidian: return String(localized: "item_external_resource_qidian", defaultValue: "起点", table: "Item", comment: "Item External Resource Name - Qidian")
        case .ypshuo: return String(localized: "item_external_resource_ypshuo", defaultValue: "阅书中文", table: "Item", comment: "Item External Resource Name - Ypshuo")
        case .bilibili: return String(localized: "item_external_resource_bilibili", defaultValue: "哔哩哔哩", table: "Item", comment: "Item External Resource Name - Bilibili")
        case .fedi: return String(localized: "item_external_resource_fedi", defaultValue: "Fediverse", table: "Item", comment: "Item External Resource Name - Fediverse")
        case .rss: return String(localized: "item_external_resource_rss", defaultValue: "RSS", table: "Item", comment: "Item External Resource Name - RSS")
        case .unknown: return nil
        }
    }
}

extension ItemExternalResourceSchema: Hashable {
    var type: ItemKnownExternalResource {
        let host = url.host?.lowercased() ?? ""
        let resource: ItemKnownExternalResource

        // Books
        if let targetHost = ItemKnownExternalResource.douban.host, host.contains(targetHost) {
            resource = .douban
        } else if let targetHost = ItemKnownExternalResource.goodreads.host, host.contains(targetHost) {
            resource = .goodreads
        } else if let targetHost = ItemKnownExternalResource.booksTW.host, host.contains(targetHost) {
            resource = .booksTW
        } else if let targetHost = ItemKnownExternalResource.googleBooks.host, host.contains(targetHost) {
            resource = .googleBooks
        }

        // Movies & TV
        else if let targetHost = ItemKnownExternalResource.imdb.host, host.contains(targetHost) {
            resource = .imdb
        } else if let targetHost = ItemKnownExternalResource.tmdb.host, host.contains(targetHost) {
            resource = .tmdb
        } else if let targetHost = ItemKnownExternalResource.bangumi.host, host.contains(targetHost) {
            resource = .bangumi
        }

        // Music
        else if let targetHost = ItemKnownExternalResource.bandcamp.host, host.contains(targetHost) {
            resource = .bandcamp
        } else if let targetHost = ItemKnownExternalResource.spotify.host, host.contains(targetHost) {
            resource = .spotify
        } else if let targetHost = ItemKnownExternalResource.appleMusic.host, host.contains(targetHost) {
            resource = .appleMusic
        } else if let targetHost = ItemKnownExternalResource.discogs.host, host.contains(targetHost) {
            resource = .discogs
        } else if let targetHost = ItemKnownExternalResource.applePodcasts.host, host.contains(targetHost) {
            resource = .applePodcasts
        }

        // Games
        else if let targetHost = ItemKnownExternalResource.igdb.host, host.contains(targetHost) {
            resource = .igdb
        } else if let targetHost = ItemKnownExternalResource.steam.host, host.contains(targetHost) {
            resource = .steam
        } else if let targetHost = ItemKnownExternalResource.bgg.host, host.contains(targetHost) {
            resource = .bgg
        }

        // Literature
        else if let targetHost = ItemKnownExternalResource.ao3.host, host.contains(targetHost) {
            resource = .ao3
        } else if let targetHost = ItemKnownExternalResource.jinjiang.host, host.contains(targetHost) {
            resource = .jinjiang
        } else if let targetHost = ItemKnownExternalResource.qidian.host, host.contains(targetHost) {
            resource = .qidian
        } else if let targetHost = ItemKnownExternalResource.ypshuo.host, host.contains(targetHost) {
            resource = .ypshuo
        }

        // Social & Others
        else if let targetHost = ItemKnownExternalResource.bilibili.host, host.contains(targetHost) {
            resource = .bilibili
        } else if let targetScheme = ItemKnownExternalResource.fedi.host, url.scheme == targetScheme {
            resource = .fedi
        } else if let targetScheme = ItemKnownExternalResource.rss.host, url.scheme == targetScheme {
            resource = .rss
        }

        // Default to unknown if no match
        else {
            resource = .unknown
        }

        return resource
    }

    var name: String {
        return type.displayName ?? url.host ?? String(localized: "item_external_resource_unknown", defaultValue: "Unknown", table: "Item", comment: "Item External Resource Name - Unknown")
    }

    var icon: String {
        return type.icon
    }
}

extension ItemExternalResourceSchema {
    func makeAppScheme() -> URL? {
        switch self.type {
        case .douban:
            let host = url.host ?? ""
            let type = host.replacingOccurrences(of: ".douban.com", with: "")
            let id = url.pathComponents.last ?? ""
            let scheme = URL(string: "douban://douban.com/\(type)/\(id)")
            if host.isEmpty || type.isEmpty || id.isEmpty {
                return nil
            }
            return scheme
        default: return nil
        }
    }
}
