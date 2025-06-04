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

public struct Person: Codable {
    public let id: Int
    public let name: String
    public let character: String?
    public let profilePath: String?
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
    
    public func trending(mediaType: MediaType, timeWindow: String = "week", language: String = "en") async throws -> [Movie] {
        // trending endpoint returns both movies and tv shows; for simplicity map to Movie using title/name
        switch mediaType {
        case .movie:
            let endpoint = "trending/movie/\(timeWindow)"
            let response: TrendingResponse<Movie> = try await request(endpoint: endpoint, queryItems: [URLQueryItem(name: "language", value: language)], type: TrendingResponse<Movie>.self)
            return response.results
        case .tv:
            let endpoint = "trending/tv/\(timeWindow)"
            let response: TrendingResponse<TVShow> = try await request(endpoint: endpoint, queryItems: [URLQueryItem(name: "language", value: language)], type: TrendingResponse<TVShow>.self)
            return response.results.map { Movie(id: $0.id, title: $0.name, overview: $0.overview, posterPath: $0.posterPath, releaseDate: $0.firstAirDate, voteAverage: $0.voteAverage) }
        }
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
    public func discoverMovies(genre: Int? = nil, language: String = "en") async throws -> [Movie] {
        var query: [URLQueryItem] = [URLQueryItem(name: "language", value: language)]
        if let genre = genre { query.append(URLQueryItem(name: "with_genres", value: String(genre))) }
        let response: SearchResponse<Movie> = try await request(endpoint: "discover/movie", queryItems: query, type: SearchResponse<Movie>.self)
        return response.results
    }
}

