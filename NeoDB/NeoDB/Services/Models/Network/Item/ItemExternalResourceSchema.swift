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
}

extension ItemExternalResourceSchema: Hashable {
    var type: ItemKnownExternalResource {
        let host = url.host?.lowercased() ?? ""
        let resource: ItemKnownExternalResource

        // Books
        if host.contains("douban.com") {
            resource = .douban
        } else if host.contains("goodreads.com") {
            resource = .goodreads
        } else if host.contains("books.com.tw") {
            resource = .booksTW
        } else if host.contains("books.google.com") {
            resource = .googleBooks
        }

        // Movies & TV
        else if host.contains("imdb.com") {
            resource = .imdb
        } else if host.contains("themoviedb.org") {
            resource = .tmdb
        } else if host.contains("bangumi.tv") {
            resource = .bangumi
        }

        // Music
        else if host.contains("bandcamp.com") {
            resource = .bandcamp
        } else if host.contains("spotify.com") {
            resource = .spotify
        } else if host.contains("music.apple.com") {
            resource = .appleMusic
        } else if host.contains("discogs.com") {
            resource = .discogs
        } else if host.contains("podcasts.apple.com") {
            resource = .applePodcasts
        }

        // Games
        else if host.contains("igdb.com") {
            resource = .igdb
        } else if host.contains("steampowered.com") {
            resource = .steam
        } else if host.contains("boardgamegeek.com") {
            resource = .bgg
        }

        // Literature
        else if host.contains("archiveofourown.org") {
            resource = .ao3
        } else if host.contains("jjwxc.net") {
            resource = .jinjiang
        } else if host.contains("qidian.com") {
            resource = .qidian
        } else if host.contains("ypshuo.com") {
            resource = .ypshuo
        }

        // Social & Others
        else if host.contains("bilibili.com") {
            resource = .bilibili
        } else if url.scheme == "fedi" {
            resource = .fedi
        } else if url.scheme == "rss" {
            resource = .rss
        }

        // Default to unknown if no match
        else {
            resource = .unknown
        }

        return resource
    }

    var name: String {
        return type != .unknown ? type.rawValue : url.host ?? "Unknown"
    }

    var icon: String {
        return type.icon
    }
}
