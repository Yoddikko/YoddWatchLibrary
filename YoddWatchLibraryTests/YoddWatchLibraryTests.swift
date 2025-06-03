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
}
