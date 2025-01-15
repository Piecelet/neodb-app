//
//  Date+RelativeTime.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import Foundation

extension Date {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 