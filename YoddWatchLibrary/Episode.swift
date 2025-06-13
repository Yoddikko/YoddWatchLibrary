import Foundation

/// A single episode of a TV show season.
public struct Episode: Identifiable, Codable {
    public let id: Int
    public let name: String
    public let overview: String?
    public let stillPath: String?
    public let seasonNumber: Int
    public let episodeNumber: Int
    public let airDate: String?
    public let voteAverage: Double?
}
