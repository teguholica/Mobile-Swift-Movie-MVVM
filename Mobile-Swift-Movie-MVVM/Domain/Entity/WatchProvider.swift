//
//  WatchProvider.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct WatchProvider: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let logoPath: String?

    public init(id: Int, name: String, logoPath: String?) {
        self.id = id
        self.name = name
        self.logoPath = logoPath
    }
}

public enum ProviderGroupKind: String, CaseIterable, Equatable, Sendable {
    case stream
    case free
    case ads
    case rent
    case buy

    public var title: String {
        switch self {
        case .stream: return "Stream"
        case .free: return "Free"
        case .ads: return "Ads"
        case .rent: return "Rent"
        case .buy: return "Buy"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .stream: return 0
        case .free: return 1
        case .ads: return 2
        case .rent: return 3
        case .buy: return 4
        }
    }
}

public struct ProviderGroup: Identifiable, Equatable, Sendable {
    public let kind: ProviderGroupKind
    public let providers: [WatchProvider]

    public var id: String { kind.rawValue }

    public init(kind: ProviderGroupKind, providers: [WatchProvider]) {
        self.kind = kind
        self.providers = providers
    }
}

public struct WatchProviders: Equatable, Sendable {
    public let link: URL?
    public let groups: [ProviderGroup]

    public init(link: URL?, groups: [ProviderGroup]) {
        self.link = link
        self.groups = groups
    }
}
