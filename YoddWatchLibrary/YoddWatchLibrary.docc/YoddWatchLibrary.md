# ``YoddWatchLibrary``

A lightweight framework providing access to The Movie Database API and basic user preferences for iOS and macOS apps.

## Overview

`TMDBClient` exposes async functions to search for movies or TV shows, retrieve trending or popular lists, fetch details with cast, discover movies (optionally by watch provider or genre) and compose image URLs. Requests are cached in memory and common HTTP errors are thrown. Streaming links are generated using the provided VixSrc URLs. Convenience helpers build dynamic ``MovieCategory`` lists for easily displaying multiple sections.

`UserPreferences` allows storing favorites, watched items, the preferred language (`en` or `it`), custom lists and playback progress.

`Movie` and `TVShow` expose additional optional details when fetching single items, such as backdrops, taglines, runtimes and genres.
`Person` now includes optional biography, birthday and place of birth when requesting individual cast members. The client also exposes endpoints to retrieve trailers and additional images for movies, TV shows and people.


## Topics

### API
- ``TMDBClient``
- ``MediaType``
- ``Movie``
- ``TVShow``
- ``MovieDetails``
- ``TVShowDetails``
- ``Episode``
- ``TMDBClient.episodes(showId:season:language:)``
- ``TMDBClient.numberOfSeasons(showId:language:)``
- ``TMDBClient.movieImages(id:)``
- ``TMDBClient.tvShowImages(id:)``
- ``TMDBClient.personImages(id:)``
- ``TMDBClient.movieTrailerURL(id:language:)``
- ``TMDBClient.tvShowTrailerURL(id:language:)``
- ``TMDBClient.personDetails(id:language:)``
- ``Person``
- ``WatchProvider``
- ``Genre``
- ``GenreInfo``
- ``ImageInfo``
- ``VideoInfo``
- ``MovieCategory``
- ``TVShowCategory``
- ``TMDBClient.defaultMovieCategories(region:language:)``
- ``TMDBClient.defaultTVShowCategories(region:language:)``

### Preferences
- ``UserPreferences``
