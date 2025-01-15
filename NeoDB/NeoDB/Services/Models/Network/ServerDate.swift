//
//  ServerDate.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//

import Foundation

public typealias ServerDate = String

extension ServerDate {
    private static var dateFormatters: [ISO8601DateFormatter] = {
        // With milliseconds: 2025-01-15T07:17:24.123Z
        let withMS = ISO8601DateFormatter()
        withMS.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Without milliseconds: 2024-11-06T16:00:00Z
        let withoutMS = ISO8601DateFormatter()
        withoutMS.formatOptions = [.withInternetDateTime]
        
        return [withMS, withoutMS]
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
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: self) {
                return date
            }
        }
        return nil
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
