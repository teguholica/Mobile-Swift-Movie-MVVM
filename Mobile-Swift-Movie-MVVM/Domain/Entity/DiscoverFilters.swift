//
//  DiscoverFilters.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum DiscoverSort: CaseIterable, Equatable, Sendable {
    case popularity
    case rating
    case newest
    case title
}

public struct DiscoverFilters: Equatable, Sendable {
    public var genreIds: [Int]
    public var yearRange: ClosedRange<Int>?
    public var minRating: Double?
    public var sort: DiscoverSort
    public var searchYear: Int?

    public init(
        genreIds: [Int] = [],
        yearRange: ClosedRange<Int>? = nil,
        minRating: Double? = nil,
        sort: DiscoverSort = .popularity,
        searchYear: Int? = nil
    ) {
        self.genreIds = genreIds
        self.yearRange = yearRange
        self.minRating = minRating
        self.sort = sort
        self.searchYear = searchYear
    }
}
