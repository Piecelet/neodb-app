//
//  ShelfType.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

enum ShelfType: String, Codable, CaseIterable {
    case wishlist
    case progress
    case complete
    case dropped

    var displayName: String {
        switch self {
        case .wishlist:
            return String(localized: "shelf_type_wishlist_label", table: "Item", comment: "Shelf type - Wishlist")
        case .progress:
            return String(localized: "shelf_type_progress_label", table: "Item", comment: "Shelf type - In progress")
        case .complete:
            return String(localized: "shelf_type_complete_label", table: "Item", comment: "Shelf type - Completed")
        case .dropped:
            return String(localized: "shelf_type_dropped_label", table: "Item", comment: "Shelf type - Dropped")
        }
    }

    var displayActionState: String {
        switch self {
        case .wishlist:
            return String(localized: "shelf_type_action_wishlist_label", table: "Item", comment: "Action state - Wishlisted")
        case .progress:
            return String(localized: "shelf_type_action_progress_label", table: "Item", comment: "Action state - In progress")
        case .complete:
            return String(localized: "shelf_type_action_complete_label", table: "Item", comment: "Action state - Completed")
        case .dropped:
            return String(localized: "shelf_type_action_dropped_label", table: "Item", comment: "Action state - Dropped")
        }
    }

    func actionNameFormat(for action: String) -> String {
        return String(format: String(localized: "shelf_type_action_name_format", table: "Item", comment: "Action state - Add to"), action)
    }

    var actionName: String {
        return actionNameFormat(for: displayName)
    }

    func displayNameForCategory(_ category: ItemCategory?) -> String {
        switch (self, category) {
        case (.wishlist, .movie):
            return String(localized: "shelf_type_wishlist_category_movie_label", table: "Item", comment: "Neutral noun without action - Wishlist - Movie - Want to watch")
        case (.wishlist, .tv), (.wishlist, .tvSeason), (.wishlist, .tvEpisode):
            return String(localized: "shelf_type_wishlist_category_tv_label", table: "Item", comment: "Neutral noun without action - Wishlist - TV - Want to watch")
        case (.wishlist, .book):
            return String(localized: "shelf_type_wishlist_category_book_label", table: "Item", comment: "Neutral noun without action - Wishlist - Book - Want to read")
        case (.wishlist, .music):
            return String(localized: "shelf_type_wishlist_category_music_label", table: "Item", comment: "Neutral noun without action - Wishlist - Music - Want to listen")
        case (.wishlist, .podcast):
            return String(localized: "shelf_type_wishlist_category_podcast_label", table: "Item", comment: "Neutral noun without action - Wishlist - Podcast - Want to listen")
        case (.wishlist, .game):
            return String(localized: "shelf_type_wishlist_category_game_label", table: "Item", comment: "Neutral noun without action - Wishlist - Game - Want to play")
        case (.wishlist, .performance), (.wishlist, .performanceProduction):
            return String(localized: "shelf_type_wishlist_category_performance_label", table: "Item", comment: "Neutral noun without action - Wishlist - Performance - Want to watch")
        case (.wishlist, .fanfic):
            return String(localized: "shelf_type_wishlist_category_fanfic_label", table: "Item", comment: "Neutral noun without action - Wishlist - Fanfic - Want to read")
        case (.wishlist, .exhibition):
            return String(localized: "shelf_type_wishlist_category_exhibition_label", table: "Item", comment: "Neutral noun without action - Wishlist - Exhibition - Want to watch")
        case (.wishlist, .collection):
            return String(localized: "shelf_type_wishlist_category_collection_label", table: "Item", comment: "Neutral noun without action - Wishlist - Collection - Want to watch")
        case (.progress, .movie):
            return String(localized: "shelf_type_progress_category_movie_label", table: "Item", comment: "Neutral noun without action - Progress - Movie - Watching")
        case (.progress, .tv), (.progress, .tvSeason), (.progress, .tvEpisode):
            return String(localized: "shelf_type_progress_category_tv_label", table: "Item", comment: "Neutral noun without action - Progress - TV - Watching")
        case (.progress, .book):
            return String(localized: "shelf_type_progress_category_book_label", table: "Item", comment: "Neutral noun without action - Progress - Book - Reading")
        case (.progress, .music):
            return String(localized: "shelf_type_progress_category_music_label", table: "Item", comment: "Neutral noun without action - Progress - Music - Listening")
        case (.progress, .podcast):
            return String(localized: "shelf_type_progress_category_podcast_label", table: "Item", comment: "Neutral noun without action - Progress - Podcast - Listening")
        case (.progress, .game):
            return String(localized: "shelf_type_progress_category_game_label", table: "Item", comment: "Neutral noun without action - Progress - Game - Playing")
        case (.progress, .performance), (.progress, .performanceProduction):
            return String(localized: "shelf_type_progress_category_performance_label", table: "Item", comment: "Neutral noun without action - Progress - Performance - Watching")
        case (.progress, .fanfic):
            return String(localized: "shelf_type_progress_category_fanfic_label", table: "Item", comment: "Neutral noun without action - Progress - Fanfic - Reading")
        case (.progress, .exhibition):
            return String(localized: "shelf_type_progress_category_exhibition_label", table: "Item", comment: "Neutral noun without action - Progress - Exhibition - Watching")
        case (.progress, .collection):
            return String(localized: "shelf_type_progress_category_collection_label", table: "Item", comment: "Neutral noun without action - Progress - Collection - Watching")
        case (.complete, .movie):
            return String(localized: "shelf_type_complete_category_movie_label", table: "Item", comment: "Neutral noun without action - Complete - Movie - Watched")
        case (.complete, .tv), (.complete, .tvSeason), (.complete, .tvEpisode):
            return String(localized: "shelf_type_complete_category_tv_label", table: "Item", comment: "Neutral noun without action - Complete - TV - Watched")
        case (.complete, .podcast):
            return String(localized: "shelf_type_complete_category_podcast_label", table: "Item", comment: "Neutral noun without action - Complete - Podcast - Listened")
        case (.complete, .book):
            return String(localized: "shelf_type_complete_category_book_label", table: "Item", comment: "Neutral noun without action - Complete - Book - Read")
        case (.complete, .music):
            return String(localized: "shelf_type_complete_category_music_label", table: "Item", comment: "Neutral noun without action - Complete - Music - Listened")
        case (.complete, .game):
            return String(localized: "shelf_type_complete_category_game_label", table: "Item", comment: "Neutral noun without action - Complete - Game - Played")
        case (.complete, .performance), (.complete, .performanceProduction):
            return String(localized: "shelf_type_complete_category_performance_label", table: "Item", comment: "Neutral noun without action - Complete - Performance - Watched")
        case (.complete, .fanfic):
            return String(localized: "shelf_type_complete_category_fanfic_label", table: "Item", comment: "Neutral noun without action - Complete - Fanfic - Read")
        case (.complete, .exhibition):
            return String(localized: "shelf_type_complete_category_exhibition_label", table: "Item", comment: "Neutral noun without action - Complete - Exhibition - Watched")
        case (.complete, .collection):
            return String(localized: "shelf_type_complete_category_collection_label", table: "Item", comment: "Neutral noun without action - Complete - Collection - Watched")
        case (.dropped, .movie):
            return String(localized: "shelf_type_dropped_category_movie_label", table: "Item", comment: "Neutral noun without action - Dropped - Movie")
        case (.dropped, .tv), (.dropped, .tvSeason), (.dropped, .tvEpisode):
            return String(localized: "shelf_type_dropped_category_tv_label", table: "Item", comment: "Neutral noun without action - Dropped - TV")
        case (.dropped, .podcast):
            return String(localized: "shelf_type_dropped_category_podcast_label", table: "Item", comment: "Neutral noun without action - Dropped - Podcast")
        case (.dropped, .book):
            return String(localized: "shelf_type_dropped_category_book_label", table: "Item", comment: "Neutral noun without action - Dropped - Book")
        case (.dropped, .music):
            return String(localized: "shelf_type_dropped_category_music_label", table: "Item", comment: "Neutral noun without action - Dropped - Music")
        case (.dropped, .game):
            return String(localized: "shelf_type_dropped_category_game_label", table: "Item", comment: "Neutral noun without action - Dropped - Game")
        case (.dropped, .performance), (.dropped, .performanceProduction):
            return String(localized: "shelf_type_dropped_category_performance_label", table: "Item", comment: "Neutral noun without action - Dropped - Performance")
        case (.dropped, .fanfic):
            return String(localized: "shelf_type_dropped_category_fanfic_label", table: "Item", comment: "Neutral noun without action - Dropped - Fanfic")
        case (.dropped, .exhibition):
            return String(localized: "shelf_type_dropped_category_exhibition_label", table: "Item", comment: "Neutral noun without action - Dropped - Exhibition")
        case (.dropped, .collection):
            return String(localized: "shelf_type_dropped_category_collection_label", table: "Item", comment: "Neutral noun without action - Dropped - Collection")
        default:
            return displayName
        }
    }

    func displayActionStateForCategory(_ category: ItemCategory?) -> String {
        switch (self, category) {
        case (.wishlist, .movie), (.wishlist, .tv), (.wishlist, .tvSeason), (.wishlist, .tvEpisode):
            return String(localized: "shelf_type_action_wishlist_category_movie_label", table: "Item", comment: "Action state - Wishlisted - Movie - Wanted to watch")
        case (.wishlist, .book):
            return String(localized: "shelf_type_action_wishlist_category_book_label", table: "Item", comment: "Action state - Wishlisted - Book - Wanted to read")
        case (.wishlist, .music):
            return String(localized: "shelf_type_action_wishlist_category_music_label", table: "Item", comment: "Action state - Wishlisted - Music - Wanted to listen")
        case (.wishlist, .podcast):
            return String(localized: "shelf_type_action_wishlist_category_podcast_label", table: "Item", comment: "Action state - Wishlisted - Podcast - Wanted to listen")
        case (.wishlist, .game):
            return String(localized: "shelf_type_action_wishlist_category_game_label", table: "Item", comment: "Action state - Wishlisted - Game - Wanted to play")
        case (.wishlist, .performance), (.wishlist, .performanceProduction):
            return String(localized: "shelf_type_action_wishlist_category_performance_label", table: "Item", comment: "Action state - Wishlisted - Performance - Wanted to watch")
        case (.wishlist, .fanfic):
            return String(localized: "shelf_type_action_wishlist_category_fanfic_label", table: "Item", comment: "Action state - Wishlisted - Fanfic - Wanted to read")
        case (.wishlist, .exhibition):
            return String(localized: "shelf_type_action_wishlist_category_exhibition_label", table: "Item", comment: "Action state - Wishlisted - Exhibition - Wanted to watch")
        case (.wishlist, .collection):
            return String(localized: "shelf_type_action_wishlist_category_collection_label", table: "Item", comment: "Action state - Wishlisted - Collection - Wanted to watch")
        case (.progress, .movie):
            return String(localized: "shelf_type_action_progress_category_movie_label", table: "Item", comment: "Action state - Progress - Movie - Watching")
        case (.progress, .tv), (.progress, .tvSeason), (.progress, .tvEpisode):
            return String(localized: "shelf_type_action_progress_category_tv_label", table: "Item", comment: "Action state - Progress - TV - Watching")
        case (.progress, .book):
            return String(localized: "shelf_type_action_progress_category_book_label", table: "Item", comment: "Action state - Progress - Book - Reading")
        case (.progress, .music):
            return String(localized: "shelf_type_action_progress_category_music_label", table: "Item", comment: "Action state - Progress - Music - Listening")
        case (.progress, .podcast):
            return String(localized: "shelf_type_action_progress_category_podcast_label", table: "Item", comment: "Action state - Progress - Podcast - Listening")
        case (.progress, .game):
            return String(localized: "shelf_type_action_progress_category_game_label", table: "Item", comment: "Action state - Progress - Game - Playing")
        case (.progress, .performance), (.progress, .performanceProduction):
            return String(localized: "shelf_type_action_progress_category_performance_label", table: "Item", comment: "Action state - Progress - Performance - Watching")
        case (.progress, .fanfic):
            return String(localized: "shelf_type_action_progress_category_fanfic_label", table: "Item", comment: "Action state - Progress - Fanfic - Reading")
        case (.progress, .exhibition):
            return String(localized: "shelf_type_action_progress_category_exhibition_label", table: "Item", comment: "Action state - Progress - Exhibition - Watching")
        case (.progress, .collection):
            return String(localized: "shelf_type_action_progress_category_collection_label", table: "Item", comment: "Action state - Progress - Collection - Watching")
        case (.complete, .movie):
            return String(localized: "shelf_type_action_complete_category_movie_label", table: "Item", comment: "Action state - Complete - Movie - Watched")
        case (.complete, .tv), (.complete, .tvSeason), (.complete, .tvEpisode):
            return String(localized: "shelf_type_action_complete_category_tv_label", table: "Item", comment: "Action state - Complete - TV - Watched")
        case (.complete, .podcast):
            return String(localized: "shelf_type_action_complete_category_podcast_label", table: "Item", comment: "Action state - Complete - Podcast - Watched")
        case (.complete, .book):
            return String(localized: "shelf_type_action_complete_category_book_label", table: "Item", comment: "Action state - Complete - Book - Read")
        case (.complete, .music):
            return String(localized: "shelf_type_action_complete_category_music_label", table: "Item", comment: "Action state - Complete - Music - Watched")
        case (.complete, .game):
            return String(localized: "shelf_type_action_complete_category_game_label", table: "Item", comment: "Action state - Complete - Game - Watched")
        case (.complete, .performance), (.complete, .performanceProduction):
            return String(localized: "shelf_type_action_complete_category_performance_label", table: "Item", comment: "Action state - Complete - Performance - Watched")
        case (.complete, .fanfic):
            return String(localized: "shelf_type_action_complete_category_fanfic_label", table: "Item", comment: "Action state - Complete - Fanfic - Read")
        case (.complete, .exhibition):
            return String(localized: "shelf_type_action_complete_category_exhibition_label", table: "Item", comment: "Action state - Complete - Exhibition - Watched")
        case (.complete, .collection):
            return String(localized: "shelf_type_action_complete_category_collection_label", table: "Item", comment: "Action state - Complete - Collection - Watched")
        case (.dropped, .movie):
            return String(localized: "shelf_type_action_dropped_category_movie_label", table: "Item", comment: "Action state - Dropped - Movie - Dropped")
        case (.dropped, .tv), (.dropped, .tvSeason), (.dropped, .tvEpisode):
            return String(localized: "shelf_type_action_dropped_category_tv_label", table: "Item", comment: "Action state - Dropped - TV - Dropped")
        case (.dropped, .podcast):
            return String(localized: "shelf_type_action_dropped_category_podcast_label", table: "Item", comment: "Action state - Dropped - Podcast - Dropped")
        case (.dropped, .book):
            return String(localized: "shelf_type_action_dropped_category_book_label", table: "Item", comment: "Action state - Dropped - Book - Dropped")
        case (.dropped, .music):
            return String(localized: "shelf_type_action_dropped_category_music_label", table: "Item", comment: "Action state - Dropped - Music - Dropped")
        case (.dropped, .game):
            return String(localized: "shelf_type_action_dropped_category_game_label", table: "Item", comment: "Action state - Dropped - Game - Dropped")
        case (.dropped, .performance), (.dropped, .performanceProduction):
            return String(localized: "shelf_type_action_dropped_category_performance_label", table: "Item", comment: "Action state - Dropped - Performance - Dropped")
        case (.dropped, .fanfic):
            return String(localized: "shelf_type_action_dropped_category_fanfic_label", table: "Item", comment: "Action state - Dropped - Fanfic - Dropped")
        case (.dropped, .exhibition):
            return String(localized: "shelf_type_action_dropped_category_exhibition_label", table: "Item", comment: "Action state - Dropped - Exhibition - Dropped")
        case (.dropped, .collection):
            return String(localized: "shelf_type_action_dropped_category_collection_label", table: "Item", comment: "Action state - Dropped - Collection - Dropped")
        default:
            return displayActionState
        }
    }

    var iconName: String {
        switch self {
        case .wishlist:
            return "star"
        case .progress:
            return "book"
        case .complete:
            return "checkmark.circle"
        case .dropped:
            return "xmark.circle"
        }
    }

    var symbolImage: Symbol {
        switch self {
        case .wishlist: return .sfSymbol(.heart)
        case .progress: return .sfSymbol(.book)
        case .complete: return .sfSymbol(.checkmarkCircle)
        case .dropped: return .sfSymbol(.xmarkCircle)
        }
    }

    var symbolImageFill: Symbol {
        switch self {
        case .wishlist: return .sfSymbol(.heartFill)
        case .progress: return .sfSymbol(.bookFill)
        case .complete: return .sfSymbol(.checkmarkCircleFill)
        case .dropped: return .sfSymbol(.xmarkCircleFill)
        }
    }
}
