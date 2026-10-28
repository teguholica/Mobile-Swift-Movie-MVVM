//
//  TMDBConfig.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum TMDBConfig {
    public static let baseURL = "https://api.themoviedb.org/3"
    public static let imageBaseURL = "https://image.tmdb.org/t/p/"

    public static var apiReadAccessToken: String {
        // 1. Try Bundle.main
        if let token = Bundle.main.object(forInfoDictionaryKey: "TMDBApiReadAccessToken") as? String,
           !token.isEmpty,
           !token.hasPrefix("YOUR_") {
            return token
        }
        // 2. Try App bundle directly
        if let appBundle = Bundle(identifier: "com.teguholica.Mobile-Swift-Movie-MVVM"),
           let token = appBundle.object(forInfoDictionaryKey: "TMDBApiReadAccessToken") as? String,
           !token.isEmpty,
           !token.hasPrefix("YOUR_") {
            return token
        }
        // 3. Search loaded bundles (e.g. test bundles)
        for bundle in Bundle.allBundles {
            if let token = bundle.object(forInfoDictionaryKey: "TMDBApiReadAccessToken") as? String,
               !token.isEmpty,
               !token.hasPrefix("YOUR_") {
                return token
            }
        }
        // 4. Fallback to environment variable (useful for CI/test schemes)
        if let envToken = ProcessInfo.processInfo.environment["TMDB_API_READ_ACCESS_TOKEN"],
           !envToken.isEmpty {
            return envToken
        }
        return ""
    }

    public static func imageURL(path: String?, size: String = "w500") -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(imageBaseURL)\(size)/\(cleanPath)")
    }
}
