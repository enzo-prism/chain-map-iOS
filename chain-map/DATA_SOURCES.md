# Chain Map Data Sources

Chain Map fetches Caltrans CWWP2 JSON feeds directly in the iOS app. A backend
service still exists in this repo, but the app can run without it. This document
captures the data sources and handling rules.

## Principles
- Prefer official DOT/road agency sources for chain control status.
- Show timestamps and mark data as stale when it exceeds the refresh window.
- Cache responses to reduce load and improve resilience during outages.

## Current sources (subject to licensing and availability)
- Caltrans CWWP2 chain controls (D03): https://cwwp2.dot.ca.gov/data/d3/cc/ccStatusD03.json
- Caltrans CWWP2 chain controls (D10): https://cwwp2.dot.ca.gov/data/d10/cc/ccStatusD10.json
- Caltrans CWWP2 lane closures (D03): https://cwwp2.dot.ca.gov/data/d3/lcs/lcsStatusD03.json
- Caltrans CWWP2 lane closures (D10): https://cwwp2.dot.ca.gov/data/d10/lcs/lcsStatusD10.json
- Optional Nevada 511 proxy (configurable): https://<proxy>/roadconditions, https://<proxy>/events

## Future sources
- Additional advisories and closures where licensing permits.

## Refresh strategy (goal)
- Chain controls: ~60 seconds.
- Lane closures: ~5 minutes.
- Back off on repeated failures and surface a stale/unknown state.
- Never infer closures that are not explicitly reported.

## Normalization
- Map source-specific fields into a shared set of statuses: clear, restrictions,
  closed, unknown.
- Preserve raw source identifiers for debugging and traceability.
