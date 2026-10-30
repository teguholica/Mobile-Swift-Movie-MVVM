//
//  AppRoute.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum AppRoute: Hashable {
    case movie(id: Int)
    case person(id: Int, name: String, profilePath: String?)
}
