//
//  ThemeManagerTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
import SwiftUI
@testable import Mobile_Swift_Movie_MVVM

@Suite(.serialized)
struct ThemeManagerTests {
    private let suiteName = "ThemeManagerTests_\(UUID().uuidString)"

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }

    @Test
    func testDefaultModeIsSystemWithNilColorScheme() {
        let defaults = makeDefaults()
        let sut = ThemeManager(userDefaults: defaults)

        #expect(sut.currentMode == .system)
        #expect(sut.colorScheme == nil)
    }

    @Test
    func testSettingLightModePersistsAndMapsToLightColorScheme() {
        let defaults = makeDefaults()
        let sut = ThemeManager(userDefaults: defaults)

        sut.currentMode = .light

        #expect(sut.currentMode == .light)
        #expect(sut.colorScheme == .light)
        #expect(defaults.string(forKey: "app_appearance_mode") == "light")
    }

    @Test
    func testSettingDarkModePersistsAndMapsToDarkColorScheme() {
        let defaults = makeDefaults()
        let sut = ThemeManager(userDefaults: defaults)

        sut.currentMode = .dark

        #expect(sut.currentMode == .dark)
        #expect(sut.colorScheme == .dark)
        #expect(defaults.string(forKey: "app_appearance_mode") == "dark")
    }

    @Test
    func testSwitchingBackToSystemModePersistsAndMapsToNilColorScheme() {
        let defaults = makeDefaults()
        let sut = ThemeManager(userDefaults: defaults)

        sut.currentMode = .dark
        #expect(sut.colorScheme == .dark)

        sut.currentMode = .system
        #expect(sut.currentMode == .system)
        #expect(sut.colorScheme == nil)
        #expect(defaults.string(forKey: "app_appearance_mode") == "system")
    }

    @Test
    func testRestoringPreExistingModeFromStorage() {
        let defaults = makeDefaults()
        defaults.set("dark", forKey: "app_appearance_mode")

        let sut = ThemeManager(userDefaults: defaults)

        #expect(sut.currentMode == .dark)
        #expect(sut.colorScheme == .dark)
    }

    @Test
    func testInvalidStoredModeFallsBackToSystem() {
        let defaults = makeDefaults()
        defaults.set("invalid_mode", forKey: "app_appearance_mode")

        let sut = ThemeManager(userDefaults: defaults)

        #expect(sut.currentMode == .system)
        #expect(sut.colorScheme == nil)
    }
}
