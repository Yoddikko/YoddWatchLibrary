# ``YoddWatchLibrary``

A lightweight framework providing access to The Movie Database API and basic user preferences for iOS and macOS apps.

## Overview

`TMDBClient` exposes async functions to search for movies or TV shows, retrieve trending or popular lists, fetch details with cast, discover movies (optionally by watch provider or genre) and compose image URLs. Requests are cached in memory and common HTTP errors are thrown. Streaming links are generated using the provided VixSrc URLs. Convenience helpers build dynamic ``MovieCategory`` lists for easily displaying multiple sections.

`UserPreferences` allows storing favorites, watched items, the preferred language (`en` or `it`), custom lists and playback progress.


## Topics

### API
- ``TMDBClient``
- ``MediaType``
- ``Movie``
- ``TVShow``
- ``MovieDetails``
- ``TVShowDetails``
- ``Person``
- ``WatchProvider``
- ``Genre``
- ``MovieCategory``
- ``TMDBClient.defaultMovieCategories(region:language:)``

### Preferences
- ``UserPreferences``
