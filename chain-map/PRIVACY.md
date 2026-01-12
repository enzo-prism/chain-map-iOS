# Chain Map Privacy

This document describes the intended privacy behavior for Chain Map. Update it
whenever data collection or permissions change.

## Data collection
- No user accounts.
- No advertising identifiers.
- No third-party analytics by default.

## Location
- Location access is optional and only used to show nearby roads on the map.
- Location is not stored or transmitted outside of required system services.

## Network
- The app fetches Caltrans CWWP2 chain control and lane closure data directly.
- The app fetches Open-Meteo snowfall history data directly.
- Responses may be cached locally for performance and offline resilience.

## Changes
If any of the above changes (analytics, accounts, sharing), update this
document and the in-app disclosure strings.
