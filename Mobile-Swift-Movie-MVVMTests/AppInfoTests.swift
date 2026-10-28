//
//  AppInfoTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct AppInfoTests {

    @Test
    func testFormattedVersionWithVersionAndBuild() {
        let appInfo = AppInfo(appName: "Movie DB", version: "1.0", build: "42")
        #expect(appInfo.formattedVersion == "1.0 (42)")
    }

    @Test
    func testFormattedVersionWithEmptyBuild() {
        let appInfo = AppInfo(appName: "Movie DB", version: "2.1", build: "")
        #expect(appInfo.formattedVersion == "2.1")
    }

    @Test
    func testFromDictionaryParsesBundleKeysCorrectly() {
        let dict: [String: Any] = [
            "CFBundleDisplayName": "Movie DB",
            "CFBundleShortVersionString": "1.5.0",
            "CFBundleVersion": "12"
        ]

        let appInfo = AppInfo.from(infoDictionary: dict)

        #expect(appInfo.appName == "Movie DB")
        #expect(appInfo.version == "1.5.0")
        #expect(appInfo.build == "12")
        #expect(appInfo.formattedVersion == "1.5.0 (12)")
    }

    @Test
    func testFromDictionaryWithNilDictionaryUsesFallbacks() {
        let appInfo = AppInfo.from(infoDictionary: nil as [String: Any]?)

        #expect(appInfo.appName == "Movie DB")
        #expect(appInfo.version == "1.0")
        #expect(appInfo.build == "1")
        #expect(appInfo.formattedVersion == "1.0 (1)")
    }

    @Test
    func testFromDictionaryWithPartialKeysUsesFallbacks() {
        let dict: [String: Any] = [
            "CFBundleShortVersionString": "2.0.0"
        ]

        let appInfo = AppInfo.from(infoDictionary: dict)

        #expect(appInfo.appName == "Movie DB")
        #expect(appInfo.version == "2.0.0")
        #expect(appInfo.build == "1")
        #expect(appInfo.formattedVersion == "2.0.0 (1)")
    }
}
