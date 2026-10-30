//
//  DiscoverFilters.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum DiscoverSort: CaseIterable, Hashable, Sendable {
    case popularity
    case rating
    case newest
    case title

    public var isDefault: Bool {
        self == .popularity
    }
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

    public var activeFilterCount: Int {
        var count = 0
        if yearRange != nil { count += 1 }
        if minRating != nil { count += 1 }
        if !sort.isDefault { count += 1 }
        return count
    }

    public var hasConstraints: Bool {
        activeFilterCount > 0
    }
}
