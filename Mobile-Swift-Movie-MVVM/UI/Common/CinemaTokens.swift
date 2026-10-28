//
//  CinemaTokens.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI
import UIKit

public enum CinemaTokens {
    public enum DynamicColors {
        public static let canvas = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 11/255, green: 12/255, blue: 16/255, alpha: 1.0)
                : UIColor(red: 248/255, green: 249/255, blue: 251/255, alpha: 1.0)
        }

        public static let surface = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 20/255, green: 22/255, blue: 31/255, alpha: 1.0)
                : UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        }

        public static let elevated = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 29/255, green: 33/255, blue: 46/255, alpha: 1.0)
                : UIColor(red: 237/255, green: 239/255, blue: 244/255, alpha: 1.0)
        }

        public static let glassStroke = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.08)
                : UIColor(white: 0.0, alpha: 0.06)
        }

        public static let textPrimary = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 244/255, green: 245/255, blue: 248/255, alpha: 1.0)
                : UIColor(red: 17/255, green: 19/255, blue: 24/255, alpha: 1.0)
        }

        public static let textSecondary = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 142/255, green: 149/255, blue: 165/255, alpha: 1.0)
                : UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1.0)
        }

        public static let textMuted = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 86/255, green: 92/255, blue: 107/255, alpha: 1.0)
                : UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1.0)
        }
    }

    public enum Colors {
        public static let canvas = Color(uiColor: DynamicColors.canvas)
        public static let surface = Color(uiColor: DynamicColors.surface)
        public static let elevated = Color(uiColor: DynamicColors.elevated)
        public static let glassStroke = Color(uiColor: DynamicColors.glassStroke)

        public static let gold = Color(red: 245/255, green: 197/255, blue: 24/255)
        public static let crimson = Color(red: 229/255, green: 9/255, blue: 20/255)
        public static let accent = gold
        public static let primary = crimson

        public static let textPrimary = Color(uiColor: DynamicColors.textPrimary)
        public static let textSecondary = Color(uiColor: DynamicColors.textSecondary)
        public static let textMuted = Color(uiColor: DynamicColors.textMuted)
    }

    public enum Radius {
        public static let card: CGFloat = 14
        public static let hero: CGFloat = 20
        public static let chip: CGFloat = 8
        public static let badge: CGFloat = 6

        public static let large: CGFloat = 20
        public static let medium: CGFloat = 14
        public static let small: CGFloat = 8
    }

    public typealias CornerRadius = Radius
}

public struct CinemaCardModifier: ViewModifier {
    public let radius: CGFloat
    public let backgroundColor: Color

    public init(radius: CGFloat = CinemaTokens.Radius.card, backgroundColor: Color = CinemaTokens.Colors.surface) {
        self.radius = radius
        self.backgroundColor = backgroundColor
    }

    public func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
            )
    }
}

public extension View {
    func cinemaCard(radius: CGFloat = CinemaTokens.Radius.card, backgroundColor: Color = CinemaTokens.Colors.surface) -> some View {
        modifier(CinemaCardModifier(radius: radius, backgroundColor: backgroundColor))
    }
}
