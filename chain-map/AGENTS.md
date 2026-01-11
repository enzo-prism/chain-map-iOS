# Chain Map Agent Guide

This repo contains Chain Map, an iOS app that presents live chain control and
winter road condition data for Tahoe and the Bay Area. The UI should follow the
Liquid Glass patterns described in:
`../AdditionalDocumentation/UIKit-Implementing-Liquid-Glass-Design.md`.

## Project facts
- App name: Chain Map
- Primary UI: SwiftUI
- Liquid Glass: UIKit-backed `UIVisualEffectView` + `UIGlassEffect` via
  `UIViewRepresentable` when needed
- Data is safety-critical: always show data freshness and include a disclaimer

## Working agreements
- Prefer SwiftUI for screens and components; isolate UIKit bridges in a small,
  reusable wrapper when Liquid Glass effects are required.
- Keep map UI lightweight: overlays should be translucent, minimal, and avoid
  occluding critical map content.
- Avoid over-promising data accuracy. If a source is unknown or delayed,
  explicitly label it.
- Keep code ASCII-only unless a file already contains Unicode.

## Suggested structure (when adding files)
- `App/`: app entry, scene setup
- `Features/`: map, alerts, favorites, settings
- `UI/`: reusable components and Liquid Glass wrappers
- `Models/`: domain types (roads, chain control levels, incidents)
- `Services/`: networking, caching, parsing

## Build and test
- Open `../chain-map.xcodeproj` in Xcode and run the iOS target.
- If you add tests, keep them fast and deterministic.

## Documentation to keep in sync
- `README.md` for product overview and setup
- `DESIGN.md` for UI patterns and Liquid Glass usage
- `ARCHITECTURE.md` for data flow and module boundaries
- `DATA_SOURCES.md` and `PRIVACY.md` for data/usage constraints
