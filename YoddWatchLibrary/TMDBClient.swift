import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
// NetworkExtension is only required when this package
// is integrated in an app target. It is not available
// on Linux, so avoid importing it here.


public enum MediaType: String {
    case movie
    case tv
}

public struct Movie: Codable {
    public let id: Int
    public let title: String
    public let overview: String?
    public let posterPath: String?
    public let releaseDate: String?
    public let voteAverage: Double?
}

public struct TVShow: Codable {
    public let id: Int
    public let name: String
    public let overview: String?
    public let posterPath: String?
    public let firstAirDate: String?
    public let voteAverage: Double?
}

public struct Person: Codable {
    public let id: Int
    public let name: String
    public let character: String?
    public let profilePath: String?
}

/// A single episode of a TV show season.
public struct Episode: Codable {
    public let id: Int
    public let name: String
    public let overview: String?
    public let stillPath: String?
    public let seasonNumber: Int
    public let episodeNumber: Int
    public let airDate: String?
    public let voteAverage: Double?
}

/// Known watch providers used by some helper methods.
public enum WatchProvider: Int {
    case netflix = 8
    case primeVideo = 9
    case disneyPlus = 337
    case appleTVPlus = 350
}

/// Basic genres used to build default movie categories.
public enum Genre: Int {
    case action = 28
    case comedy = 35
    case drama = 18
}

/// A dynamic list of movies belonging to a specific category.
public class MovieCategory {
    public let id = UUID()
    public let name: String
    private let loader: (_ page: Int) async throws -> [Movie]
    private(set) public var page: Int = 0
    public private(set) var items: [Movie] = []

    public init(name: String, loader: @escaping (_ page: Int) async throws -> [Movie]) {
        self.name = name
        self.loader = loader
    }

    /// Reloads the first page of results, replacing current items.
    @discardableResult
    public func reload() async throws -> [Movie] {
        page = 1
        items = try await loader(page)
        return items
    }

    /// Fetches the next page and appends the results.
    @discardableResult
    public func loadNext() async throws -> [Movie] {
        page += 1
        let more = try await loader(page)
        items.append(contentsOf: more)
        return more
    }
}

public struct MovieDetails: Codable {
    public let movie: Movie
    public let cast: [Person]
}

public struct TVShowDetails: Codable {
    public let show: TVShow
    public let cast: [Person]
}

struct CreditsResponse: Codable {
    let cast: [Person]
}

struct SearchResponse<T: Codable>: Codable {
    let results: [T]
}

struct TrendingResponse<T: Codable>: Codable {
    let results: [T]
}

public enum TMDBError: Error {
    case invalidResponse
    case httpError(Int)
    case decodeError
}

public class TMDBClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!
    private let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!
    private let cache = NSCache<NSURL, NSData>()
    
    public init?(apiKey: String? = ProcessInfo.processInfo.environment["TMDB_API_KEY"]) {
        guard let key = apiKey else { return nil }
        self.apiKey = key
    }
    
    private func request<T: Codable>(endpoint: String, queryItems: [URLQueryItem] = [], type: T.Type) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        var items = [URLQueryItem(name: "api_key", value: apiKey)]
        items.append(contentsOf: queryItems)
        components.queryItems = items
        let url = components.url!
        if let cached = cache.object(forKey: url as NSURL) {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: cached as Data)
            } catch {
                throw TMDBError.decodeError
            }
        }
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw TMDBError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw TMDBError.httpError(http.statusCode) }
        cache.setObject(data as NSData, forKey: url as NSURL)
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TMDBError.decodeError
        }
    }
    
    public func searchMovies(query: String, language: String = "en") async throws -> [Movie] {
        let response: SearchResponse<Movie> = try await request(endpoint: "search/movie", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "language", value: language)
        ], type: SearchResponse<Movie>.self)
        return response.results
    }
    
    public func searchTVShows(query: String, language: String = "en") async throws -> [TVShow] {
        let response: SearchResponse<TVShow> = try await request(endpoint: "search/tv", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "language", value: language)
        ], type: SearchResponse<TVShow>.self)
        return response.results
    }
    
    public func trending(mediaType: MediaType, timeWindow: String = "week", language: String = "en", page: Int = 1) async throws -> [Movie] {
        switch mediaType {
        case .movie:
            return try await trendingMovies(timeWindow: timeWindow, language: language, page: page)
        case .tv:
            return try await trendingTVShows(timeWindow: timeWindow, language: language, page: page)
        }
    }

    /// Trending movies for the given time window (`day` or `week`).
    public func trendingMovies(timeWindow: String = "week", language: String = "en", page: Int = 1) async throws -> [Movie] {
        let endpoint = "trending/movie/\(timeWindow)"
        let response: TrendingResponse<Movie> = try await request(endpoint: endpoint, queryItems: [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))], type: TrendingResponse<Movie>.self)
        return response.results
    }

    /// Trending TV shows mapped to ``Movie`` for convenience.
    public func trendingTVShows(timeWindow: String = "week", language: String = "en", page: Int = 1) async throws -> [Movie] {
        let endpoint = "trending/tv/\(timeWindow)"
        let response: TrendingResponse<TVShow> = try await request(endpoint: endpoint, queryItems: [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))], type: TrendingResponse<TVShow>.self)
        return response.results.map {
            Movie(id: $0.id, title: $0.name, overview: $0.overview, posterPath: $0.posterPath, releaseDate: $0.firstAirDate, voteAverage: $0.voteAverage)
        }
    }

    private func asMovies(_ shows: [TVShow]) -> [Movie] {
        shows.map { Movie(id: $0.id, title: $0.name, overview: $0.overview, posterPath: $0.posterPath, releaseDate: $0.firstAirDate, voteAverage: $0.voteAverage) }
    }
    
    public func movieDetails(id: Int, language: String = "en") async throws -> MovieDetails {
        async let movie: Movie = request(endpoint: "movie/\(id)", queryItems: [URLQueryItem(name: "language", value: language)], type: Movie.self)
        async let creditsResp: CreditsResponse = request(endpoint: "movie/\(id)/credits", queryItems: [], type: CreditsResponse.self)
        let m = try await movie
        let credits = try await creditsResp
        return MovieDetails(movie: m, cast: credits.cast)
    }
    
    public func tvShowDetails(id: Int, language: String = "en") async throws -> TVShowDetails {
        async let show: TVShow = request(endpoint: "tv/\(id)", queryItems: [URLQueryItem(name: "language", value: language)], type: TVShow.self)
        async let creditsResp: CreditsResponse = request(endpoint: "tv/\(id)/credits", queryItems: [], type: CreditsResponse.self)
        let s = try await show
        let credits = try await creditsResp
        return TVShowDetails(show: s, cast: credits.cast)
    }

    /// Fetches the episodes for a specific season of a TV show.
    public func episodes(showId: Int, season: Int, language: String = "en") async throws -> [Episode] {
        struct SeasonResponse: Codable { let episodes: [Episode] }
        let response: SeasonResponse = try await request(
            endpoint: "tv/\(showId)/season/\(season)",
            queryItems: [URLQueryItem(name: "language", value: language)],
            type: SeasonResponse.self
        )
        return response.episodes
    }

    /// Retrieves the number of seasons available for the given TV show.
    public func numberOfSeasons(showId: Int, language: String = "en") async throws -> Int {
        struct ShowInfo: Codable { let numberOfSeasons: Int }
        let info: ShowInfo = try await request(
            endpoint: "tv/\(showId)",
            queryItems: [URLQueryItem(name: "language", value: language)],
            type: ShowInfo.self
        )
        return info.numberOfSeasons
    }

    // MARK: Top/Popular
    public func popularMovies(language: String = "en", page: Int = 1) async throws -> [Movie] {
        let response: SearchResponse<Movie> = try await request(
            endpoint: "movie/popular",
            queryItems: [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))],
            type: SearchResponse<Movie>.self)
        return response.results
    }

    public func topRatedMovies(language: String = "en", page: Int = 1) async throws -> [Movie] {
        let response: SearchResponse<Movie> = try await request(
            endpoint: "movie/top_rated",
            queryItems: [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))],
            type: SearchResponse<Movie>.self)
        return response.results
    }

    public func popularTVShows(language: String = "en", page: Int = 1) async throws -> [TVShow] {
        let response: SearchResponse<TVShow> = try await request(
            endpoint: "tv/popular",
            queryItems: [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))],
            type: SearchResponse<TVShow>.self)
        return response.results
    }

    public func topRatedTVShows(language: String = "en", page: Int = 1) async throws -> [TVShow] {
        let response: SearchResponse<TVShow> = try await request(
            endpoint: "tv/top_rated",
            queryItems: [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))],
            type: SearchResponse<TVShow>.self)
        return response.results
    }

    /// Discover TV shows available on a specific watch provider, sorted by popularity.
    public func topTVShows(provider: WatchProvider, region: String = "US", language: String = "en", page: Int = 1) async throws -> [TVShow] {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "with_watch_providers", value: String(provider.rawValue)),
            URLQueryItem(name: "watch_region", value: region),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "page", value: String(page))
        ]
        let response: SearchResponse<TVShow> = try await request(endpoint: "discover/tv", queryItems: query, type: SearchResponse<TVShow>.self)
        return response.results
    }

    /// Discover movies available on a specific watch provider, sorted by popularity.
    public func topMovies(provider: WatchProvider, region: String = "US", language: String = "en", page: Int = 1) async throws -> [Movie] {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "with_watch_providers", value: String(provider.rawValue)),
            URLQueryItem(name: "watch_region", value: region),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "page", value: String(page))
        ]
        let response: SearchResponse<Movie> = try await request(endpoint: "discover/movie", queryItems: query, type: SearchResponse<Movie>.self)
        return response.results
    }
    
    // MARK: Streaming Links
    public func movieStreamingURL(tmdbId: Int) -> URL {
        URL(string: "https://vixsrc.to/movie/\(tmdbId)")!
    }
    
    public func showStreamingURL(tmdbId: Int, season: Int, episode: Int) -> URL {
        URL(string: "https://vixsrc.to/tv/\(tmdbId)/\(season)/\(episode)")!
    }
    
    // MARK: Images
    public func imageURL(path: String, size: String = "w500") -> URL {
        imageBaseURL.appendingPathComponent(size).appendingPathComponent(path)
    }
    
    // MARK: Discover
    public func discoverMovies(genre: Int? = nil, language: String = "en", page: Int = 1) async throws -> [Movie] {
        var query: [URLQueryItem] = [URLQueryItem(name: "language", value: language), URLQueryItem(name: "page", value: String(page))]
        if let genre = genre { query.append(URLQueryItem(name: "with_genres", value: String(genre))) }
        let response: SearchResponse<Movie> = try await request(endpoint: "discover/movie", queryItems: query, type: SearchResponse<Movie>.self)
        return response.results
    }

    // MARK: Category Helpers
    /// Convenience method returning a set of common movie categories.
    public func defaultMovieCategories(region: String = "US", language: String = "en") -> [MovieCategory] {
        [
            MovieCategory(name: "Trending") { page in
                try await self.trendingMovies(language: language, page: page)
            },
            MovieCategory(name: "Top Rated") { page in
                try await self.topRatedMovies(language: language, page: page)
            },
            MovieCategory(name: "Top on Netflix") { page in
                try await self.topMovies(provider: .netflix, region: region, language: language, page: page)
            },
            MovieCategory(name: "Top on Prime Video") { page in
                try await self.topMovies(provider: .primeVideo, region: region, language: language, page: page)
            },
            MovieCategory(name: "Action") { page in
                try await self.discoverMovies(genre: Genre.action.rawValue, language: language, page: page)
            },
            MovieCategory(name: "Comedy") { page in
                try await self.discoverMovies(genre: Genre.comedy.rawValue, language: language, page: page)
            }
        ]
    }

    /// Returns default categories and optionally preloads the first page of each one.
    public func defaultMovieCategories(region: String = "US", language: String = "en", preload: Bool) async throws -> [MovieCategory] {
        let categories = defaultMovieCategories(region: region, language: language)
        if preload {
            for category in categories {
                try await category.reload()
            }
        }
        return categories
    }

    /// Convenience method returning a set of common TV show categories.
    public func defaultTVShowCategories(region: String = "US", language: String = "en") -> [MovieCategory] {
        [
            MovieCategory(name: "Trending") { page in
                try await self.trendingTVShows(language: language, page: page)
            },
            MovieCategory(name: "Top Rated") { page in
                let shows = try await self.topRatedTVShows(language: language, page: page)
                return self.asMovies(shows)
            },
            MovieCategory(name: "Popular") { page in
                let shows = try await self.popularTVShows(language: language, page: page)
                return self.asMovies(shows)
            },
            MovieCategory(name: "Top on Netflix") { page in
                let shows = try await self.topTVShows(provider: .netflix, region: region, language: language, page: page)
                return self.asMovies(shows)
            },
            MovieCategory(name: "Top on Prime Video") { page in
                let shows = try await self.topTVShows(provider: .primeVideo, region: region, language: language, page: page)
                return self.asMovies(shows)
            }
        ]
    }

    /// Returns default TV show categories and optionally preloads the first page of each one.
    public func defaultTVShowCategories(region: String = "US", language: String = "en", preload: Bool) async throws -> [MovieCategory] {
        let categories = defaultTVShowCategories(region: region, language: language)
        if preload {
            for category in categories {
                try await category.reload()
            }
        }
        return categories
    }
}

