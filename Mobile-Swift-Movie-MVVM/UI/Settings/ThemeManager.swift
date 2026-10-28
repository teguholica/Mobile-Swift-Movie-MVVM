//
//  ThemeManager.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI
import Observation

public enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@Observable
public final class ThemeManager {
    public static let storageKey = "app_appearance_mode"

    private let userDefaults: UserDefaults

    public var currentMode: AppearanceMode {
        didSet {
            userDefaults.set(currentMode.rawValue, forKey: Self.storageKey)
        }
    }

    public var colorScheme: ColorScheme? {
        currentMode.colorScheme
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let storedValue = userDefaults.string(forKey: Self.storageKey),
           let mode = AppearanceMode(rawValue: storedValue) {
            self.currentMode = mode
        } else {
            self.currentMode = .system
        }
    }
}
