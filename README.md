# Chain Map

Chain Map is an iOS app and optional backend service that surface live chain
control and winter road conditions for Tahoe and the Bay Area.

## Repo layout
- `chain-map/`: iOS app source (SwiftUI)
- `backend/`: Node 20 + TypeScript ingestion service and JSON API
- `AdditionalDocumentation/`: Apple platform references for design and APIs

## Quick start
1. iOS app: open `chain-map.xcodeproj` in Xcode and run the app target.
2. Optional backend: `cd backend && npm install && npm run dev`.
3. App parsing tests: `swift test`.

## Documentation
- App docs live in `chain-map/README.md` and `chain-map/DESIGN.md`.
- Backend docs live in `backend/README.md`.
