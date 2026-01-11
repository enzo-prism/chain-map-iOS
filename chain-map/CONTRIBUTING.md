# Contributing to Chain Map

Thanks for helping build Chain Map. This project is still early; keep changes
small and easy to review.

## Development setup
- Use the latest stable Xcode.
- Open `../chain-map.xcodeproj` and run the iOS target.

## Code standards
- Prefer SwiftUI for UI, with UIKit wrappers only where Liquid Glass is needed.
- Keep view models lightweight and push work into services.
- Use async/await for network calls and avoid blocking the main thread.

## Testing
- Add tests for new parsing or normalization logic.
- Run tests before submitting changes when they exist.

## Documentation
- Update `README.md`, `DESIGN.md`, and `DATA_SOURCES.md` if behavior changes.
