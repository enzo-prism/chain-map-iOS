# Chain Map Data Sources

Chain Map currently fetches Caltrans QuickMap chain control data directly in the
iOS app. A backend service still exists in this repo, but the app can run
without it. This document captures the data sources and handling rules.

## Principles
- Prefer official DOT/road agency sources for chain control status.
- Show timestamps and mark data as stale when it exceeds the refresh window.
- Cache responses to reduce load and improve resilience during outages.

## Current sources (subject to licensing and availability)
- Caltrans QuickMap chain control KML: https://quickmap.dot.ca.gov/data/cc.kml

## Future sources
- Additional advisories and closures where licensing permits.

## Refresh strategy (goal)
- Poll at a fixed cadence (for example, 5-10 minutes).
- Back off on repeated failures and surface a stale/unknown state.
- Never infer closures that are not explicitly reported.

## Normalization
- Map source-specific fields into a shared set of statuses: clear, restrictions,
  closed, unknown.
- Preserve raw source identifiers for debugging and traceability.
