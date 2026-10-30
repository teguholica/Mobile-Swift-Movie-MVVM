//
//  PersonDateFormattingTests.swift
//  Mobile-Swift-Movie-MVVM
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct PersonDateFormattingTests {
    private let english = Locale(identifier: "en_US")

    @Test func mediumDateFormatsISO8601Date() {
        let formatted = PersonDateFormatting.mediumDate(from: "1994-06-23", locale: english)

        #expect(formatted == "Jun 23, 1994")
    }

    @Test func mediumDateReturnsRawStringWhenUnparseable() {
        let formatted = PersonDateFormatting.mediumDate(from: "not-a-date", locale: english)

        #expect(formatted == "not-a-date")
    }

    @Test func mediumDateReturnsNilForMissingOrEmptyValues() {
        #expect(PersonDateFormatting.mediumDate(from: nil, locale: english) == nil)
        #expect(PersonDateFormatting.mediumDate(from: "", locale: english) == nil)
    }

    @Test func ageUsesReferenceDate() throws {
        let referenceDate = try #require(PersonDateFormatting.parse("2026-10-30"))

        let age = PersonDateFormatting.age(from: "1994-06-23", on: referenceDate)

        #expect(age == 32)
    }

    @Test func ageAtDeathUsesDeathDate() {
        let age = PersonDateFormatting.ageAtDeath(
            birthday: "1956-07-09",
            deathday: "2020-01-01"
        )

        #expect(age == 63)
    }

    @Test func ageIsNilForInvalidBirthday() {
        let referenceDate = Date(timeIntervalSince1970: 0)

        #expect(PersonDateFormatting.age(from: "not-a-date", on: referenceDate) == nil)
        #expect(PersonDateFormatting.ageAtDeath(birthday: "1956-07-09", deathday: nil) == nil)
    }
}
