//
//  ServerDate.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

public typealias ServerDate = String

extension ServerDate {
    private static var createdAtDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        return formatter
    }()

    private static var createdAtRelativeFormatter: RelativeDateTimeFormatter {
        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.unitsStyle = .abbreviated
        return dateFormatter
    }

    private static var createdAtShortDateFormatted: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }

    public var asDate: Date? {
        Self.createdAtDateFormatter.date(from: self)
    }

    public var formatted: String {
        guard let date = asDate else { return self }

        let calendar = Calendar(identifier: .gregorian)
        if calendar.numberOfDaysBetween(date, and: Date()) > 1 {
            return Self.createdAtShortDateFormatted.string(from: date)
        } else {
            return Self.createdAtRelativeFormatter.localizedString(
                for: date, relativeTo: Date())
        }
    }
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)

        return numberOfDays.day!
    }
}
