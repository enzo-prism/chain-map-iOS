# Chain Map Data Sources

Chain Map uses a backend service to ingest official DOT data sources. The app
only calls the backend and never hits DOT endpoints directly. This document
captures the data sources and handling rules.

## Principles
- Prefer official DOT/road agency sources for chain control status.
- Show timestamps and mark data as stale when it exceeds the refresh window.
- Cache responses to reduce load and improve resilience during outages.

## Current sources (subject to licensing and availability)
- Caltrans QuickMap chain control KML: https://quickmap.dot.ca.gov/data/cc.kml
- Nevada 511 road conditions JSON: https://www.nvroads.com/api/v2/get/roadconditions

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
