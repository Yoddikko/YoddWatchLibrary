//
//  YoddWatchLibraryTests.swift
//  YoddWatchLibraryTests
//

import Foundation
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

    @Test func defaultMovieCategories() throws {
        let client = TMDBClient(apiKey: "test")!
        let categories = client.defaultMovieCategories()
        #expect(!categories.isEmpty)
        let names = categories.map { $0.name }
        #expect(names.contains("Trending"))
        #expect(names.contains("Top Rated"))
    }

    @Test func defaultMovieCategoriesPreload() async throws {
        let client = TMDBClient(apiKey: "test")!
        let categories = try await client.defaultMovieCategories(preload: false)
        #expect(!categories.isEmpty)
    }

    @Test func defaultTVShowCategories() throws {
        let client = TMDBClient(apiKey: "test")!
        let categories = client.defaultTVShowCategories()
        #expect(!categories.isEmpty)
        let names = categories.map { $0.name }
        #expect(names.contains("Trending"))
        #expect(names.contains("Top Rated"))
    }

    @Test func defaultTVShowCategoriesPreload() async throws {
        let client = TMDBClient(apiKey: "test")!
        let categories = try await client.defaultTVShowCategories(preload: false)
        #expect(!categories.isEmpty)
    }

    @Test func decodeEpisode() throws {
        let json = """
        {
            "id": 1,
            "name": "Pilot",
            "overview": "Intro",
            "still_path": "/img.jpg",
            "season_number": 1,
            "episode_number": 1,
            "air_date": "2022-01-01",
            "vote_average": 7.5
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let episode = try decoder.decode(Episode.self, from: json)
        #expect(episode.id == 1)
        #expect(episode.seasonNumber == 1)
        #expect(episode.episodeNumber == 1)
    }

    @Test func decodeMovieDetails() throws {
        let json = """
        {
            "id": 10,
            "title": "Example",
            "overview": "Test",
            "poster_path": "/p.jpg",
            "backdrop_path": "/b.jpg",
            "release_date": "2024-01-01",
            "vote_average": 8.0,
            "runtime": 120,
            "tagline": "Tag",
            "homepage": "https://example.com",
            "genres": [{"id": 1, "name": "Drama"}],
            "status": "Released",
            "budget": 1000000,
            "revenue": 5000000,
            "imdb_id": "tt1234567"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let movie = try decoder.decode(Movie.self, from: json)
        #expect(movie.id == 10)
        #expect(movie.runtime == 120)
        #expect(movie.genres?.first?.name == "Drama")
        #expect(movie.status == "Released")
        #expect(movie.budget == 1000000)
        #expect(movie.imdbId == "tt1234567")
    }

    @Test func decodeVideoInfo() throws {
        let json = """
        {
            "name": "Trailer",
            "key": "abc",
            "site": "YouTube",
            "type": "Trailer",
            "size": 1080,
            "official": true,
            "published_at": "2024-01-01",
            "id": "v1"
        }
        """.data(using: .utf8)!
        let video = try JSONDecoder().decode(VideoInfo.self, from: json)
        #expect(video.key == "abc")
        #expect(video.size == 1080)
        #expect(video.official == true)
        #expect(video.id == "v1")
    }

    @Test func decodePersonDetails() throws {
        let json = """
        {
            "id": 1,
            "name": "Actor",
            "character": "Role",
            "profile_path": "/p.jpg",
            "biography": "An actor",
            "birthday": "1970-01-01",
            "place_of_birth": "Somewhere"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let person = try decoder.decode(Person.self, from: json)
        #expect(person.biography == "An actor")
        #expect(person.birthday == "1970-01-01")
        #expect(person.placeOfBirth == "Somewhere")
    }

    @Test func decodeMediaImages() throws {
        let json = """
        {
            "posters": [{"file_path": "/p.jpg", "width": 500, "height": 750, "iso_639_1": "en", "aspect_ratio": 0.7}],
            "backdrops": [{"file_path": "/b.jpg", "width": 1280, "height": 720, "iso_639_1": "en", "aspect_ratio": 1.77}],
            "logos": [{"file_path": "/l.png", "width": 200, "height": 100, "iso_639_1": "en", "aspect_ratio": 2.0}]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let images = try decoder.decode(MediaImages.self, from: json)
        #expect(images.logos.first?.filePath == "/l.png")
        #expect(images.logos.first?.iso6391 == "en")
        #expect(images.posters.count == 1)
        #expect(images.backdrops.count == 1)
    }

}
