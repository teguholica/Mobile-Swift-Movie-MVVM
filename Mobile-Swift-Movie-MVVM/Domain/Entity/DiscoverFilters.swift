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
    public let genreIds: [Int]
    public let yearRange: ClosedRange<Int>?
    public let minRating: Double?
    public let sort: DiscoverSort
    public let searchYear: Int?

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
