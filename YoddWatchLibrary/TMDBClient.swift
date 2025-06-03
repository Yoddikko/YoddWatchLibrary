import Foundation
import NetworkExtension

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

struct SearchResponse<T: Codable>: Codable {
    let results: [T]
}

struct TrendingResponse<T: Codable>: Codable {
    let results: [T]
}

public class TMDBClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!

    public init?(apiKey: String? = ProcessInfo.processInfo.environment["TMDB_API_KEY"]) {
        guard let key = apiKey else { return nil }
        self.apiKey = key
    }

    private func request<T: Codable>(endpoint: String, queryItems: [URLQueryItem] = [], type: T.Type) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        var items = [URLQueryItem(name: "api_key", value: apiKey)]
        items.append(contentsOf: queryItems)
        components.queryItems = items
        let urlRequest = URLRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        return try JSONDecoder().decode(T.self, from: data)
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

    public func trending(mediaType: MediaType, language: String = "en") async throws -> [Movie] {
        // trending endpoint returns both movies and tv shows; for simplicity map to Movie using title/name
        switch mediaType {
        case .movie:
            let response: TrendingResponse<Movie> = try await request(endpoint: "trending/movie/week", queryItems: [URLQueryItem(name: "language", value: language)], type: TrendingResponse<Movie>.self)
            return response.results
        case .tv:
            let response: TrendingResponse<TVShow> = try await request(endpoint: "trending/tv/week", queryItems: [URLQueryItem(name: "language", value: language)], type: TrendingResponse<TVShow>.self)
            return response.results.map { Movie(id: $0.id, title: $0.name, overview: $0.overview, posterPath: $0.posterPath, releaseDate: $0.firstAirDate, voteAverage: $0.voteAverage) }
        }
    }

    public func movieDetails(id: Int, language: String = "en") async throws -> Movie {
        try await request(endpoint: "movie/\(id)", queryItems: [URLQueryItem(name: "language", value: language)], type: Movie.self)
    }

    public func tvShowDetails(id: Int, language: String = "en") async throws -> TVShow {
        try await request(endpoint: "tv/\(id)", queryItems: [URLQueryItem(name: "language", value: language)], type: TVShow.self)
    }

    // MARK: Streaming Links
    public func movieStreamingURL(tmdbId: Int) -> URL {
        URL(string: "https://vixsrc.to/movie/\(tmdbId)")!
    }

    public func showStreamingURL(tmdbId: Int, season: Int, episode: Int) -> URL {
        URL(string: "https://vixsrc.to/tv/\(tmdbId)/\(season)/\(episode)")!
    }
}

