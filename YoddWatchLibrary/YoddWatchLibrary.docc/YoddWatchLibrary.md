# ``YoddWatchLibrary``

A lightweight framework providing access to The Movie Database API and basic user preferences for iOS and macOS apps.

## Overview

`TMDBClient` exposes async functions to search for movies or TV shows, retrieve trending content, fetch details with cast, discover movies and compose image URLs. Requests are cached in memory and common HTTP errors are thrown. Streaming links are generated using the provided VixSrc URLs.

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

### Preferences
- ``UserPreferences``
