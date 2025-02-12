//
//  StatusItemViewModel.swift
//  NeoDB
//
//  Created by citron on 1/19/25.
//

import Foundation
import OSLog

@MainActor
class StatusItemViewModel: ObservableObject {
    @Published var item: any ItemProtocol

    var displayTitle: AttributedString {
        var title = AttributedString(item.displayTitle ?? "")
        if let movie = item as? MovieSchema, let year = movie.year {
            var yearString = AttributedString(" (\(year))")
            yearString.foregroundColor = .secondary
            title += yearString
        }
        return title
    }
    
    init(item: any ItemProtocol) {
        self.item = item
    }
} 
