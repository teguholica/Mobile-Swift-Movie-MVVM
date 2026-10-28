//
//  AppInfo.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct AppInfo: Sendable, Equatable {
    public let appName: String
    public let version: String
    public let build: String

    public var formattedVersion: String {
        if build.isEmpty {
            return version
        }
        return "\(version) (\(build))"
    }

    public init(
        appName: String = "Movie DB",
        version: String = "1.0",
        build: String = "1"
    ) {
        self.appName = appName
        self.version = version
        self.build = build
    }

    public static func from(
        infoDictionary: [String: Any]?,
        fallbackAppName: String = "Movie DB",
        fallbackVersion: String = "1.0",
        fallbackBuild: String = "1"
    ) -> AppInfo {
        let name = (infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (infoDictionary?["CFBundleName"] as? String)
            ?? fallbackAppName
        let version = (infoDictionary?["CFBundleShortVersionString"] as? String) ?? fallbackVersion
        let build = (infoDictionary?["CFBundleVersion"] as? String) ?? fallbackBuild

        return AppInfo(appName: name, version: version, build: build)
    }

    public static func current(bundle: Bundle = .main) -> AppInfo {
        from(infoDictionary: bundle.infoDictionary)
    }
}
