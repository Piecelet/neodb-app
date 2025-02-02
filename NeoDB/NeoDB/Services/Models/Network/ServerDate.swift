//
//  ServerDate.swift
//  NeoDB
//
//  Created by citron on 1/13/25.
//
//  From https://github.com/Dimillian/IceCubesApp
//  Witch is licensed under the AGPL-3.0 License
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

    public enum FormatStyle {
        case dateOnly
        case dateAndTime
    }

    public func formatted(_ style: FormatStyle = .dateAndTime) -> String {
        guard let date = asDate else {
            return self
        }
        switch style {
        case .dateOnly:
            return date.formatted(date: .abbreviated, time: .omitted)
        case .dateAndTime:
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }

    public var shortDateFormatted: String {
        guard let date = asDate else {
            return self
        }
        return Self.createdAtShortDateFormatted.string(from: date)
    }

    public var relativeFormatted: String {
        guard let date = asDate else {
            return self
        }
        let aDay: TimeInterval = 60 * 60 * 24
        if Date().timeIntervalSince(date) >= aDay {
            return Self.createdAtRelativeFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            let secondsDiff = -date.timeIntervalSinceNow
            return Duration.seconds(secondsDiff).formatted(
                .units(width: .narrow, maximumUnitCount: 1)
            )
        }
    }

    static func from(_ date: Date) -> ServerDate {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return ServerDate(formatter.string(from: date))
    }
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day ?? 0
    }
}
