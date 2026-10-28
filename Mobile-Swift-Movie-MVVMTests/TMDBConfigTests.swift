//
//  TMDBConfigTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

@Suite struct TMDBConfigTests {
    @Test
    func testBaseURLsAreValid() {
        #expect(TMDBConfig.baseURL == "https://api.themoviedb.org/3")
        #expect(TMDBConfig.imageBaseURL == "https://image.tmdb.org/t/p/")
    }

    @Test
    func testImageURLGeneration() {
        let url = TMDBConfig.imageURL(path: "/poster123.jpg", size: "w500")
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w500/poster123.jpg")

        let emptyURL = TMDBConfig.imageURL(path: "")
        #expect(emptyURL == nil)

        let nilURL = TMDBConfig.imageURL(path: nil)
        #expect(nilURL == nil)
    }

    @Test
    func testApiReadAccessTokenResolvesConfiguredToken() {
        let token = TMDBConfig.apiReadAccessToken
        #expect(!token.isEmpty)
        #expect(!token.hasPrefix("YOUR_"))
    }
}
