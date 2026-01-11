# Chain Map

Chain Map is an iOS app that surfaces live chain control requirements and winter
road conditions for Tahoe and the Bay Area in a fast, glanceable map UI.

Status: early prototype. The UI and data integrations are still being built.

## Goals
- Make chain control status easy to understand at a glance.
- Highlight closures and restrictions without hiding the map.
- Keep data freshness explicit and avoid over-promising accuracy.

## Tech stack
- SwiftUI for primary UI
- UIKit bridges for Liquid Glass material effects
- MapKit for map rendering and overlays

## Getting started
1. Open `../chain-map.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Build and run the app target.

## Data source
- The app fetches Caltrans QuickMap chain control KML directly:
  `https://quickmap.dot.ca.gov/data/cc.kml`
- Updates run on a 2-5 minute timer and cache the last result on-device.

## Tests
- Run `swift test` from the repo root to validate KML parsing and caching.

## Documentation
- `DESIGN.md` for Liquid Glass UI patterns and visual rules
- `ARCHITECTURE.md` for data flow and module boundaries
- `DATA_SOURCES.md` for data source notes and constraints
- `PRIVACY.md` for intended privacy behavior
- `ROADMAP.md` for upcoming milestones

## Safety note
Chain control data is informational only. Always follow official guidance and
roadside signage.
