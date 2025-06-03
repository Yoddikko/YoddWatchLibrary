import Foundation

public class UserPreferences {
    public static let shared = UserPreferences()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let favorites = "favorites"
        static let watched = "watched"
        static let preferredLanguage = "preferredLanguage"
    }

    public var preferredLanguage: String {
        get { defaults.string(forKey: Keys.preferredLanguage) ?? Locale.preferredLanguages.first ?? "en" }
        set {
            guard newValue == "en" || newValue == "it" else { return }
            defaults.set(newValue, forKey: Keys.preferredLanguage)
        }
    }

    public var favorites: [Int] {
        get { defaults.array(forKey: Keys.favorites) as? [Int] ?? [] }
        set { defaults.set(newValue, forKey: Keys.favorites) }
    }

    public var watched: [Int] {
        get { defaults.array(forKey: Keys.watched) as? [Int] ?? [] }
        set { defaults.set(newValue, forKey: Keys.watched) }
    }

    public func addFavorite(id: Int) {
        var current = favorites
        if !current.contains(id) {
            current.append(id)
            favorites = current
        }
    }

    public func removeFavorite(id: Int) {
        favorites = favorites.filter { $0 != id }
    }

    public func markWatched(id: Int) {
        var current = watched
        if !current.contains(id) {
            current.append(id)
            watched = current
        }
    }
}
