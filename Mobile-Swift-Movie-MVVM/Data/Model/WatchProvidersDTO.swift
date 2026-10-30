//
//  WatchProvidersDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct WatchProvidersResponseDTO: Decodable, Sendable {
    public let results: [String: RegionProvidersDTO]
}

public struct RegionProvidersDTO: Decodable, Sendable {
    public let link: String?
    public let flatrate: [WatchProviderDTO]?
    public let free: [WatchProviderDTO]?
    public let ads: [WatchProviderDTO]?
    public let rent: [WatchProviderDTO]?
    public let buy: [WatchProviderDTO]?

    private enum CodingKeys: String, CodingKey {
        case link
        case flatrate
        case free
        case ads
        case rent
        case buy
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.link = try container.decodeIfPresent(String.self, forKey: .link)
        self.flatrate = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .flatrate)
        self.free = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .free)
        self.ads = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .ads)
        self.rent = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .rent)
        self.buy = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .buy)
    }
}

public struct WatchProviderDTO: Decodable, Sendable {
    public let providerId: Int
    public let providerName: String
    public let logoPath: String?
    public let displayPriority: Int

    private enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
        case providerName = "provider_name"
        case logoPath = "logo_path"
        case displayPriority = "display_priority"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.providerId = try container.decodeIfPresent(Int.self, forKey: .providerId) ?? 0
        self.providerName = try container.decodeIfPresent(String.self, forKey: .providerName) ?? ""
        self.logoPath = try container.decodeIfPresent(String.self, forKey: .logoPath)
        self.displayPriority = try container.decodeIfPresent(Int.self, forKey: .displayPriority) ?? Int.max
    }

    public func toDomain() -> WatchProvider {
        WatchProvider(id: providerId, name: providerName, logoPath: logoPath)
    }
}
