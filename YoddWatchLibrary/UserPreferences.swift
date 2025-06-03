import Foundation

public class UserPreferences {
    public static let shared = UserPreferences()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let favorites = "favorites"
        static let watched = "watched"
        static let preferredLanguage = "preferredLanguage"
        static let lists = "lists"
        static let progress = "progress"
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

    public var lists: [String: [Int]] {
        get { defaults.dictionary(forKey: Keys.lists) as? [String: [Int]] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.lists) }
    }

    public var progress: [Int: Double] {
        get {
            guard let dict = defaults.dictionary(forKey: Keys.progress) as? [String: Double] else { return [:] }
            var result: [Int: Double] = [:]
            for (k, v) in dict { if let id = Int(k) { result[id] = v } }
            return result
        }
        set {
            var dict: [String: Double] = [:]
            for (k, v) in newValue { dict[String(k)] = v }
            defaults.set(dict, forKey: Keys.progress)
        }
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

    // MARK: Lists
    public func addList(name: String) {
        var all = lists
        if all[name] == nil { all[name] = [] }
        lists = all
    }

    public func add(_ id: Int, toList name: String) {
        var all = lists
        var arr = all[name] ?? []
        if !arr.contains(id) { arr.append(id) }
        all[name] = arr
        lists = all
    }

    public func remove(_ id: Int, fromList name: String) {
        var all = lists
        guard var arr = all[name] else { return }
        arr.removeAll { $0 == id }
        all[name] = arr
        lists = all
    }

    // MARK: Progress
    public func setProgress(id: Int, minutes: Double) {
        var prog = progress
        prog[id] = minutes
        progress = prog
    }

    public func progress(for id: Int) -> Double? {
        progress[id]
    }
}
