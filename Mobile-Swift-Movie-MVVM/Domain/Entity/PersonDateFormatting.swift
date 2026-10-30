//
//  PersonDateFormatting.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum PersonDateFormatting {
    private static let utcTimeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current

    public static func mediumDate(
        from value: String?,
        locale: Locale = .current
    ) -> String? {
        guard let value, !value.isEmpty else { return nil }
        guard let date = parse(value) else { return value }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = utcTimeZone
        return formatter.string(from: date)
    }

    public static func age(
        from birthday: String?,
        on referenceDate: Date = Date()
    ) -> Int? {
        guard let birthday, let birthDate = parse(birthday) else { return nil }
        let components = utcCalendar.dateComponents([.year], from: birthDate, to: referenceDate)
        guard let years = components.year, years >= 0 else { return nil }
        return years
    }

    public static func ageAtDeath(
        birthday: String?,
        deathday: String?
    ) -> Int? {
        guard let deathday, let deathDate = parse(deathday) else { return nil }
        return age(from: birthday, on: deathDate)
    }

    static func parse(_ value: String) -> Date? {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        return calendar.date(from: components)
    }

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        return calendar
    }
}
