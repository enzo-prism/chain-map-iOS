# Chain Map

Chain Map is an iOS app that surfaces live chain control requirements and winter
road conditions for Tahoe and the Bay Area in a fast, glanceable map UI with a
text-first status list.

Status: early prototype. The UI and data integrations are still being built.

## Goals
- Make chain control status easy to understand at a glance.
- Highlight closures and restrictions without hiding the map.
- Offer a text-first status view for key routes.
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
- The app fetches Caltrans CWWP2 JSON feeds directly (no backend required):
  - Chain controls (D03): `https://cwwp2.dot.ca.gov/data/d3/cc/ccStatusD03.json`
  - Chain controls (D10): `https://cwwp2.dot.ca.gov/data/d10/cc/ccStatusD10.json`
  - Lane closures (D03): `https://cwwp2.dot.ca.gov/data/d3/lcs/lcsStatusD03.json`
  - Lane closures (D10): `https://cwwp2.dot.ca.gov/data/d10/lcs/lcsStatusD10.json`
- Chain controls refresh every 60 seconds; lane closures refresh every 5 minutes.
- The app caches the last-known-good snapshot on-device.

## Tests
- Run `swift test` from the repo root to validate feed parsing and caching.

## Documentation
- `DESIGN.md` for Liquid Glass UI patterns and visual rules
- `ARCHITECTURE.md` for data flow and module boundaries
- `DATA_SOURCES.md` for data source notes and constraints
- `PRIVACY.md` for intended privacy behavior
- `ROADMAP.md` for upcoming milestones

## Safety note
Chain control data is informational only. Always follow official guidance and
roadside signage.
