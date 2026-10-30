//
//  DiscoverSort+Title.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

extension DiscoverSort {
    var title: String {
        switch self {
        case .popularity:
            return "Popularity"
        case .rating:
            return "Rating"
        case .newest:
            return "Newest"
        case .title:
            return "Title"
        }
    }
}
