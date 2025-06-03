//
//  YoddWatchLibraryTests.swift
//  YoddWatchLibraryTests
//

import Testing
@testable import YoddWatchLibrary

struct YoddWatchLibraryTests {

    @Test func streamingLinks() async throws {
        let client = TMDBClient(apiKey: "test")!
        let movieURL = client.movieStreamingURL(tmdbId: 1)
        #expect(movieURL.absoluteString == "https://vixsrc.to/movie/1")
        let showURL = client.showStreamingURL(tmdbId: 2, season: 1, episode: 3)
        #expect(showURL.absoluteString == "https://vixsrc.to/tv/2/1/3")
    }

    @Test func userPreferences() throws {
        let prefs = UserPreferences.shared
        prefs.favorites = []
        prefs.addFavorite(id: 7)
        #expect(prefs.favorites.contains(7))
        prefs.addList(name: "watchlist")
        prefs.add(7, toList: "watchlist")
        #expect(prefs.lists["watchlist"]?.contains(7) == true)
        prefs.setProgress(id: 7, minutes: 42)
        #expect(prefs.progress(for: 7) == 42)
    }
}
