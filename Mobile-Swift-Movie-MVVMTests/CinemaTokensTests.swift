//
//  CinemaTokensTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import SwiftUI
import UIKit
@testable import Mobile_Swift_Movie_MVVM

@Suite struct CinemaTokensTests {
    @Test
    func testColorTokensResolveNonNilValues() {
        _ = CinemaTokens.Colors.canvas
        _ = CinemaTokens.Colors.surface
        _ = CinemaTokens.Colors.elevated
        _ = CinemaTokens.Colors.glassStroke
        _ = CinemaTokens.Colors.gold
        _ = CinemaTokens.Colors.crimson
        _ = CinemaTokens.Colors.textPrimary
        _ = CinemaTokens.Colors.textSecondary
        _ = CinemaTokens.Colors.textMuted
    }

    @Test
    func testDynamicColorsAdaptToDarkAndLightTraits() {
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)

        let darkCanvas = CinemaTokens.DynamicColors.canvas.resolvedColor(with: darkTrait)
        let lightCanvas = CinemaTokens.DynamicColors.canvas.resolvedColor(with: lightTrait)

        #expect(darkCanvas != lightCanvas)

        let darkSurface = CinemaTokens.DynamicColors.surface.resolvedColor(with: darkTrait)
        let lightSurface = CinemaTokens.DynamicColors.surface.resolvedColor(with: lightTrait)

        #expect(darkSurface != lightSurface)
    }

    @Test
    func testCornerRadiiValues() {
        #expect(CinemaTokens.Radius.card == 14)
        #expect(CinemaTokens.Radius.hero == 20)
        #expect(CinemaTokens.Radius.chip == 8)
        #expect(CinemaTokens.Radius.badge == 6)
    }
}
