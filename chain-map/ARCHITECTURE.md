# Chain Map Architecture

This document describes the intended architecture for Chain Map as it grows
beyond the initial prototype.

## High-level flow
Data sources -> on-device parsing -> cache -> view models -> SwiftUI views

## Backend (optional)
The `/backend` service can ingest DOT data and expose a JSON API, but the iOS app
currently fetches Caltrans QuickMap KML directly.

## Layers
- UI: SwiftUI views with lightweight view models for the map and status list.
- Domain: models for roads, chain control status, incidents, and regions.
- Services: data fetching, parsing, caching, and freshness calculation.

## Suggested modules
- `Features/Map`: map rendering, overlays, and status chips.
- `Features/Details`: bottom sheet with segment details and advisories.
- `Features/Alerts`: notifications and watchlists (optional).
- `Services/ChainControlService`: fetch + normalize chain control data.
- `Services/Cache`: short-lived cache with explicit expiry.

## State management
- Use `ObservableObject` or `@Observable` for view models.
- Use dependency injection via initializers; avoid global singletons.
- Share a single `CorridorsViewModel` across tabs to avoid duplicate polling.
- Keep asynchronous work in services; views should only render state.

## Map rendering
- MapKit is the base layer.
- Overlays and annotations should be lightweight and updated incrementally.
- Separate visual styling from data normalization to keep rendering fast.

## Data freshness
- Every surfaced status should include a timestamp.
- Unknown or stale data should be clearly labeled and visually de-emphasized.
